function Disconnect-S2DCluster {
    <#
    .SYNOPSIS
        Disconnects from the active S2D cluster session and releases resources.

    .DESCRIPTION
        Removes any CIM or PS sessions created by Connect-S2DCluster and resets the
        module-scoped session state. Call this when you are done with the cluster or
        before connecting to a different cluster.

    .EXAMPLE
        Disconnect-S2DCluster

    .EXAMPLE
        # Connect, do work, then disconnect
        Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential $cred
        Get-S2DPhysicalDiskInventory
        Disconnect-S2DCluster
    #>
    [CmdletBinding()]
    param()

    if (-not $Script:S2DSession.IsConnected) {
        Write-Verbose "No active S2DCartographer session to disconnect."
        return
    }

    $clusterName = $Script:S2DSession.ClusterName

    if ($Script:S2DSession.CimSession) {
        try {
            $Script:S2DSession.CimSession | Remove-CimSession -ErrorAction SilentlyContinue
            Write-Verbose "CimSession to '$clusterName' removed."
        }
        catch {
            Write-Warning "Error removing CimSession: $_"
        }
    }

    if ($Script:S2DSession.PSSession) {
        try {
            $Script:S2DSession.PSSession | Remove-PSSession -ErrorAction SilentlyContinue
            Write-Verbose "PSSession to '$clusterName' removed."
        }
        catch {
            Write-Warning "Error removing PSSession: $_"
        }
    }

    $Script:S2DSession = @{
        ClusterName    = $null
        ClusterFqdn    = $null
        Nodes          = @()
        CimSession     = $null
        PSSession      = $null
        IsConnected    = $false
        IsLocal        = $false
        Authentication = 'Negotiate'
        Credential     = $null
        CollectedData  = @{}
    }

    Write-Verbose "Disconnected from '$clusterName'."
}
