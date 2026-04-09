# S2DCartographer root module loader

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleFolders = @(
    (Join-Path $moduleRoot 'Modules\Classes'),
    (Join-Path $moduleRoot 'Modules\Private'),
    (Join-Path $moduleRoot 'Modules\Collectors'),
    (Join-Path $moduleRoot 'Modules\Outputs\Reports'),
    (Join-Path $moduleRoot 'Modules\Outputs\Templates'),
    (Join-Path $moduleRoot 'Modules\Outputs\Diagrams'),
    (Join-Path $moduleRoot 'Modules\Public')
)

foreach ($folder in $moduleFolders) {
    if (Test-Path -Path $folder) {
        Get-ChildItem -Path $folder -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            ForEach-Object { . $_.FullName }
    }
}

# Module-scoped session state — shared by all cmdlets
$Script:S2DSession = @{
    ClusterName   = $null
    ClusterFqdn   = $null
    Nodes         = @()
    CimSession    = $null
    PSSession     = $null
    IsConnected   = $false
    IsLocal       = $false
    CollectedData = @{}
}

Export-ModuleMember -Function @(
    'Connect-S2DCluster',
    'Disconnect-S2DCluster',
    'Invoke-S2DCartographer',
    'Get-S2DPhysicalDiskInventory',
    'Get-S2DStoragePoolInfo',
    'Get-S2DVolumeMap',
    'Get-S2DCacheTierInfo',
    'Get-S2DHealthStatus',
    'Get-S2DCapacityWaterfall',
    'New-S2DReport',
    'New-S2DDiagram',
    'ConvertTo-S2DCapacity'
)
