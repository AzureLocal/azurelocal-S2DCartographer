function Invoke-S2DCartographer {
    <#
    .SYNOPSIS
        Full orchestrated S2D analysis run: connect, collect, analyze, and report.

    .DESCRIPTION
        Runs the complete S2DCartographer pipeline in a single call:
          1. Connect to the cluster (Connect-S2DCluster)
          2. Collect all data (physical disks, pool, volumes, cache tier)
          3. Compute the 8-stage capacity waterfall
          4. Run all 10 health checks
          5. Generate requested report formats (HTML, Word, PDF, Excel)
          6. Generate SVG diagrams (if -IncludeDiagrams)
          7. Disconnect from the cluster

        Output files are written to OutputDirectory (default: C:\S2DCartographer).
        Use -PassThru to receive the S2DClusterData object for further processing.

    .PARAMETER ClusterName
        Cluster name or FQDN. Required unless -CimSession, -PSSession, or -Local is used.

    .PARAMETER Credential
        PSCredential for cluster authentication. Resolved from Key Vault when -KeyVaultName is provided.

    .PARAMETER CimSession
        Existing CimSession to the cluster. Skips Connect-S2DCluster.

    .PARAMETER Local
        Run locally from a cluster node.

    .PARAMETER KeyVaultName
        Azure Key Vault name to resolve credentials from.

    .PARAMETER SecretName
        Key Vault secret name containing the cluster password.

    .PARAMETER OutputDirectory
        Root folder for all output files. Created if it does not exist.
        Defaults to C:\S2DCartographer.

    .PARAMETER Format
        Report formats to generate: Html, Word, Pdf, Excel, All.
        Defaults to Html.

    .PARAMETER IncludeDiagrams
        Also generate all six SVG diagram types.

    .PARAMETER PrimaryUnit
        Preferred display unit for capacity values: TiB (default) or TB.

    .PARAMETER SkipHealthChecks
        Skip the health check phase (faster runs when only capacity data is needed).

    .PARAMETER Author
        Author name embedded in generated reports.

    .PARAMETER Company
        Company or organization name embedded in generated reports.

    .PARAMETER PassThru
        Return the S2DClusterData object in addition to writing files.

    .EXAMPLE
        Invoke-S2DCartographer -ClusterName tplabs-clus01.azrl.mgmt `
            -KeyVaultName kv-tplabs-platform -SecretName lcm-deployment-password

    .EXAMPLE
        $data = Invoke-S2DCartographer -ClusterName tplabs-clus01 -Format All -IncludeDiagrams -PassThru
        $data | New-S2DReport -Format Html

    .OUTPUTS
        string[] file paths (default), or S2DClusterData when -PassThru is set.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string] $ClusterName,

        [Parameter()]
        [PSCredential] $Credential,

        [Parameter()]
        [CimSession] $CimSession,

        [Parameter()]
        [switch] $Local,

        [Parameter()]
        [string] $KeyVaultName,

        [Parameter()]
        [string] $SecretName,

        [Parameter()]
        [string] $OutputDirectory = 'C:\S2DCartographer',

        [Parameter()]
        [ValidateSet('Html', 'Word', 'Pdf', 'Excel', 'All')]
        [string[]] $Format = @('Html'),

        [Parameter()]
        [switch] $IncludeDiagrams,

        [Parameter()]
        [ValidateSet('TiB', 'TB')]
        [string] $PrimaryUnit = 'TiB',

        [Parameter()]
        [switch] $SkipHealthChecks,

        [Parameter()]
        [string] $Author = '',

        [Parameter()]
        [string] $Company = '',

        [Parameter()]
        [switch] $PassThru
    )

    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    $ownedSession = $false

    try {
        # ── Step 1: Connect ───────────────────────────────────────────────────
        if (-not $Script:S2DSession.IsConnected) {
            $connectParams = @{}
            if ($ClusterName)   { $connectParams['ClusterName'] = $ClusterName }
            if ($Credential)    { $connectParams['Credential']  = $Credential }
            if ($CimSession)    { $connectParams['CimSession']  = $CimSession }
            if ($Local)         { $connectParams['Local']       = $Local }
            if ($KeyVaultName)  { $connectParams['KeyVaultName'] = $KeyVaultName }
            if ($SecretName)    { $connectParams['SecretName']   = $SecretName }

            if ($PSCmdlet.ShouldProcess($ClusterName, 'Connect to S2D cluster')) {
                Connect-S2DCluster @connectParams
                $ownedSession = $true
            }
        }

        Write-Progress -Activity 'S2DCartographer' -Status 'Collecting physical disks...' -PercentComplete 10
        $physDisks = @(Get-S2DPhysicalDiskInventory)

        Write-Progress -Activity 'S2DCartographer' -Status 'Collecting storage pool...' -PercentComplete 25
        $pool = Get-S2DStoragePoolInfo

        Write-Progress -Activity 'S2DCartographer' -Status 'Collecting volumes...' -PercentComplete 40
        $volumes = @(Get-S2DVolumeMap)

        Write-Progress -Activity 'S2DCartographer' -Status 'Analyzing cache tier...' -PercentComplete 55
        $cacheTier = Get-S2DCacheTierInfo

        Write-Progress -Activity 'S2DCartographer' -Status 'Computing capacity waterfall...' -PercentComplete 65
        $waterfall = Get-S2DCapacityWaterfall

        $healthChecks  = @()
        $overallHealth = 'Unknown'
        if (-not $SkipHealthChecks) {
            Write-Progress -Activity 'S2DCartographer' -Status 'Running health checks...' -PercentComplete 75
            $healthChecks  = @(Get-S2DHealthStatus)
            $overallHealth = [string]$Script:S2DSession.CollectedData['OverallHealth']
        }

        # ── Step 2: Assemble S2DClusterData ───────────────────────────────────
        $clusterData = [S2DClusterData]::new()
        $clusterData.ClusterName      = $Script:S2DSession.ClusterName
        $clusterData.ClusterFqdn      = $Script:S2DSession.ClusterFqdn
        $clusterData.NodeCount        = if ($Script:S2DSession.Nodes.Count -gt 0) { $Script:S2DSession.Nodes.Count } else { 0 }
        $clusterData.Nodes            = $Script:S2DSession.Nodes
        $clusterData.CollectedAt      = Get-Date
        $clusterData.PhysicalDisks    = $physDisks
        $clusterData.StoragePool      = $pool
        $clusterData.Volumes          = $volumes
        $clusterData.CacheTier        = $cacheTier
        $clusterData.CapacityWaterfall = $waterfall
        $clusterData.HealthChecks     = $healthChecks
        $clusterData.OverallHealth    = $overallHealth

        # ── Step 3: Generate reports ──────────────────────────────────────────
        $outputFiles = @()
        if ($Format) {
            Write-Progress -Activity 'S2DCartographer' -Status 'Generating reports...' -PercentComplete 85
            $reportParams = @{
                InputObject     = $clusterData
                Format          = $Format
                OutputDirectory = $OutputDirectory
                Author          = $Author
                Company         = $Company
            }
            $outputFiles += @(New-S2DReport @reportParams)
        }

        # ── Step 4: Generate diagrams ─────────────────────────────────────────
        if ($IncludeDiagrams) {
            Write-Progress -Activity 'S2DCartographer' -Status 'Generating diagrams...' -PercentComplete 95
            $outputFiles += @(New-S2DDiagram -InputObject $clusterData -DiagramType All -OutputDirectory $OutputDirectory)
        }

        Write-Progress -Activity 'S2DCartographer' -Completed

        if ($PassThru) { return $clusterData }
        $outputFiles

    }
    finally {
        if ($ownedSession -and $Script:S2DSession.IsConnected) {
            Disconnect-S2DCluster
        }
    }
}
