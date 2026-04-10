@{
    RootModule           = 'S2DCartographer.psm1'
    ModuleVersion        = '0.1.0'
    CompatiblePSEditions = @('Core')
    GUID                 = 'c7f4a2d1-83e6-4b19-a05c-9d2e7f318c44'
    Author               = 'Azure Local Cloud'
    CompanyName          = 'countrycloudboy'
    Copyright            = '(c) 2026 Hybrid Cloud Solutions. All rights reserved.'
    Description          = 'Storage Spaces Direct analysis, visualization, and reporting for Azure Local and Windows Server clusters. Inventories physical disks, storage pools, and volumes; computes capacity waterfalls with TiB/TB dual display; generates HTML dashboards, Word documents, PDFs, and Excel workbooks with publication-quality diagrams.'
    PowerShellVersion    = '7.0'

    FunctionsToExport    = @(
        'Connect-S2DCluster',
        'Disconnect-S2DCluster',
        'Get-S2DPhysicalDiskInventory',
        'ConvertTo-S2DCapacity'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'S2D',
                'StorageSpacesDirect',
                'AzureLocal',
                'AzureStackHCI',
                'Storage',
                'HCI',
                'HyperConverged',
                'Reporting',
                'Visualization',
                'Capacity',
                'CapacityPlanning',
                'PowerShell'
            )
            ProjectUri   = 'https://azurelocal.cloud/azurelocal-s2dcartographer/'
            LicenseUri   = 'https://github.com/AzureLocal/azurelocal-S2DCartographer/blob/main/LICENSE'
            IconUri      = 'https://raw.githubusercontent.com/AzureLocal/azurelocal-S2DCartographer/main/docs/assets/images/s2dcartographer-icon.svg'
            Prerelease   = 'preview2'
            ReleaseNotes = @'
## v0.1.0-preview2 — Bug fix: non-domain-joined connectivity

### Bug Fixes
- Fixed Connect-S2DCluster failing on non-domain-joined management machines.
  S2D validation now uses Get-StoragePool via CIM instead of Get-ClusterS2D,
  which required the local FailoverClusters RSAT module.
- Fixed cluster node discovery to use MSCluster_Node CIM class via remote
  session instead of Get-ClusterNode (also requires local RSAT).

## v0.1.0-preview1 — Foundation preview

Phase 1 foundation: S2DCapacity class, ConvertTo-S2DCapacity,
Connect-S2DCluster, Disconnect-S2DCluster, and Get-S2DPhysicalDiskInventory.
'@
        }
    }
}
