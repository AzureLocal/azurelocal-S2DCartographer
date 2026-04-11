function Connect-S2DCluster {
    <#
    .SYNOPSIS
        Establishes an authenticated session to an S2D-enabled Failover Cluster.

    .DESCRIPTION
        Connect-S2DCluster creates and stores a module-scoped session that all other
        S2DCartographer cmdlets use. After connecting, you do not need to pass credentials
        to each collector.

        Supports five connection methods:
          1. ClusterName + Credential       — WinRM/CIM to a cluster node
          2. CimSession                     — re-use an existing CimSession
          3. PSSession                      — re-use an existing PSSession
          4. Local                          — run directly on a cluster node (no remoting)
          5. ClusterName + KeyVaultName     — retrieve credentials from Azure Key Vault

        The cmdlet validates that the target has S2D enabled via Get-ClusterS2D before
        storing the session.

    .PARAMETER ClusterName
        DNS name or FQDN of the Failover Cluster (e.g. "c01-prd-bal" or "c01-prd-bal.corp.local").

    .PARAMETER Credential
        PSCredential to authenticate with. Prompted interactively if not supplied.

    .PARAMETER Authentication
        Authentication method passed to New-CimSession. Defaults to 'Negotiate', which
        auto-selects NTLM or Kerberos and works in both domain-joined and workgroup/lab
        environments. Use 'Kerberos' to enforce Kerberos explicitly.

    .PARAMETER CimSession
        An existing CimSession to use instead of creating a new one.

    .PARAMETER PSSession
        An existing PSSession to use instead of creating a new one.

    .PARAMETER Local
        Run against the local machine. Use this when executing directly on a cluster node.

    .PARAMETER KeyVaultName
        Azure Key Vault name to retrieve credentials from. Requires Az.KeyVault.

    .PARAMETER SecretName
        Name of the Key Vault secret containing the password (username encoded as secret tags or prefixed by convention).

    .EXAMPLE
        Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential (Get-Credential)

    .EXAMPLE
        # Non-domain or cross-domain client — use Negotiate to avoid Kerberos failure
        Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential (Get-Credential) -Authentication Negotiate

    .EXAMPLE
        $cim = New-CimSession -ComputerName "node01" -Credential $cred
        Connect-S2DCluster -CimSession $cim

    .EXAMPLE
        Connect-S2DCluster -Local

    .EXAMPLE
        Connect-S2DCluster -ClusterName "c01-prd-bal" -KeyVaultName "kv-hcs-01" -SecretName "cluster-admin"
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName',      Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'ByKeyVault',  Mandatory, Position = 0)]
        [string] $ClusterName,

        [Parameter(ParameterSetName = 'ByName')]
        [PSCredential] $Credential,

        [Parameter(ParameterSetName = 'ByName')]
        [ValidateSet('Default','Digest','Negotiate','Basic','Kerberos','ClientCertificate','CredSsp')]
        [string] $Authentication = 'Negotiate',

        [Parameter(ParameterSetName = 'ByCimSession', Mandatory)]
        [CimSession] $CimSession,

        [Parameter(ParameterSetName = 'ByPSSession', Mandatory)]
        [System.Management.Automation.Runspaces.PSSession] $PSSession,

        [Parameter(ParameterSetName = 'Local', Mandatory)]
        [switch] $Local,

        [Parameter(ParameterSetName = 'ByKeyVault', Mandatory)]
        [string] $KeyVaultName,

        [Parameter(ParameterSetName = 'ByKeyVault', Mandatory)]
        [string] $SecretName
    )

    # Ensure not already connected
    if ($Script:S2DSession.IsConnected) {
        Write-Warning "Already connected to cluster '$($Script:S2DSession.ClusterName)'. Call Disconnect-S2DCluster first."
        return
    }

    switch ($PSCmdlet.ParameterSetName) {

        'ByName' {
            Write-Verbose "Connecting to cluster '$ClusterName' via CIM/WinRM (Authentication: $Authentication)..."
            $cimParams = @{
                ComputerName   = $ClusterName
                Authentication = $Authentication
                ErrorAction    = 'Stop'
            }
            if ($Credential) { $cimParams['Credential'] = $Credential }
            $session = New-CimSession @cimParams
            $Script:S2DSession.CimSession    = $session
            $Script:S2DSession.ClusterName   = $ClusterName
        }

        'ByCimSession' {
            Write-Verbose "Using provided CimSession to '$($CimSession.ComputerName)'..."
            $Script:S2DSession.CimSession  = $CimSession
            $Script:S2DSession.ClusterName = $CimSession.ComputerName
        }

        'ByPSSession' {
            Write-Verbose "Using provided PSSession to '$($PSSession.ComputerName)'..."
            $Script:S2DSession.PSSession   = $PSSession
            $Script:S2DSession.ClusterName = $PSSession.ComputerName
        }

        'Local' {
            Write-Verbose "Connecting in local mode (no remoting)..."
            $Script:S2DSession.IsLocal     = $true
            $Script:S2DSession.ClusterName = $env:COMPUTERNAME
        }

        'ByKeyVault' {
            Write-Verbose "Retrieving credentials from Key Vault '$KeyVaultName' secret '$SecretName'..."
            if (-not (Get-Command Get-AzKeyVaultSecret -ErrorAction SilentlyContinue)) {
                throw "Az.KeyVault module is required for Key Vault credential retrieval. Install with: Install-Module Az.KeyVault"
            }
            $secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText -ErrorAction Stop
            # Convention: secret value is the password; username stored in ContentType tag as "domain\user"
            $username = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName).ContentType
            if (-not $username) {
                throw "Key Vault secret '$SecretName' does not have a username in ContentType. Set ContentType to 'domain\\username'."
            }
            $kvCred = [PSCredential]::new($username, (ConvertTo-SecureString $secret -AsPlainText -Force))
            $session = New-CimSession -ComputerName $ClusterName -Credential $kvCred -ErrorAction Stop
            $Script:S2DSession.CimSession    = $session
            $Script:S2DSession.ClusterName   = $ClusterName
        }
    }

    # Validate that S2D is enabled on the target
    # Uses Get-StoragePool via CIM/remoting — avoids requiring local FailoverClusters RSAT module
    try {
        $s2dPool = if ($Script:S2DSession.IsLocal) {
            Get-StoragePool -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -ne 'Primordial' }
        } elseif ($Script:S2DSession.CimSession) {
            Get-StoragePool -CimSession $Script:S2DSession.CimSession -ErrorAction SilentlyContinue |
                Where-Object { $_.FriendlyName -ne 'Primordial' }
        } else {
            Invoke-Command -Session $Script:S2DSession.PSSession -ScriptBlock {
                Get-StoragePool -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -ne 'Primordial' }
            } -ErrorAction Stop
        }

        if (-not $s2dPool) {
            throw "No S2D storage pool found on '$($Script:S2DSession.ClusterName)'. Ensure Storage Spaces Direct is enabled."
        }
    }
    catch {
        # Clean up partially-created sessions on failure
        if ($Script:S2DSession.CimSession) { $Script:S2DSession.CimSession | Remove-CimSession -ErrorAction SilentlyContinue }
        $Script:S2DSession = @{
            ClusterName   = $null; ClusterFqdn = $null; Nodes = @()
            CimSession    = $null; PSSession   = $null
            IsConnected   = $false; IsLocal     = $false; CollectedData = @{}
        }
        throw "Failed to validate S2D on '$ClusterName': $_"
    }

    # Discover cluster nodes via remoting — avoids requiring local FailoverClusters RSAT module
    try {
        $Script:S2DSession.Nodes = if ($Script:S2DSession.IsLocal) {
            (Get-ClusterNode -ErrorAction SilentlyContinue).Name
        } elseif ($Script:S2DSession.CimSession) {
            Invoke-CimMethod -CimSession $Script:S2DSession.CimSession `
                -Namespace 'root/MSCluster' -ClassName 'MSCluster_Node' `
                -MethodName 'EnumerateNode' -ErrorAction SilentlyContinue | Out-Null
            (Get-CimInstance -CimSession $Script:S2DSession.CimSession `
                -Namespace 'root/MSCluster' -ClassName 'MSCluster_Node' `
                -ErrorAction SilentlyContinue).Name
        } else {
            Invoke-Command -Session $Script:S2DSession.PSSession -ScriptBlock { (Get-ClusterNode).Name }
        }
    }
    catch {
        Write-Warning "Could not enumerate cluster nodes: $_"
    }

    $Script:S2DSession.IsConnected = $true

    [PSCustomObject]@{
        ClusterName = $Script:S2DSession.ClusterName
        Nodes       = $Script:S2DSession.Nodes
        Connected   = $true
        Method      = $PSCmdlet.ParameterSetName
    }
}
