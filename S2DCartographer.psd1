@{
    RootModule           = 'S2DCartographer.psm1'
    ModuleVersion        = '1.0.2'
    CompatiblePSEditions = @('Core')
    GUID                 = 'c7f4a2d1-83e6-4b19-a05c-9d2e7f318c44'
    Author               = 'Azure Local Cloud'
    CompanyName          = 'countrycloudboy'
    Copyright            = '(c) 2026 Hybrid Cloud Solutions. All rights reserved.'
    Description          = 'Storage Spaces Direct analysis, visualization, and reporting for Azure Local and Windows Server clusters. Inventories physical disks, storage pools, and volumes; computes capacity waterfalls with TiB/TB dual display; generates HTML dashboards, Word documents, PDFs, and Excel workbooks with publication-quality diagrams.'
    PowerShellVersion    = '7.2'

    FunctionsToExport    = @(
        'Connect-S2DCluster',
        'Disconnect-S2DCluster',
        'Get-S2DPhysicalDiskInventory',
        'Get-S2DStoragePoolInfo',
        'Get-S2DVolumeMap',
        'Get-S2DCacheTierInfo',
        'Get-S2DCapacityWaterfall',
        'Get-S2DHealthStatus',
        'ConvertTo-S2DCapacity',
        'Invoke-S2DCartographer',
        'New-S2DReport',
        'New-S2DDiagram'
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
            ProjectUri   = 'https://github.com/AzureLocal/azurelocal-S2DCartographer'
            LicenseUri   = 'https://github.com/AzureLocal/azurelocal-S2DCartographer/blob/main/LICENSE'
            IconUri      = 'https://raw.githubusercontent.com/AzureLocal/azurelocal-S2DCartographer/main/docs/assets/images/s2dcartographer-icon.svg'
            ReleaseNotes = @'
## v1.0.2 — Fix WinRM authentication for non-domain and cross-domain environments

### Fixed in 1.0.2
- Per-node CIM sessions in `Get-S2DPhysicalDiskInventory` now inherit Authentication
  method and Credential from the module session, fixing WinRM Kerberos failures when
  the client is not domain-joined or is in a different domain (#31)
- `Connect-S2DCluster -KeyVaultName` path now uses `-Authentication Negotiate` instead
  of relying on the Kerberos default
- `Invoke-S2DCartographer` now accepts and passes through `-Authentication` to
  `Connect-S2DCluster`
- Session state (`$Script:S2DSession`) now stores Authentication and Credential for
  reuse by downstream collectors

## v1.0.0 — First stable release

Full pipeline from cluster connection to publication-quality reports and diagrams.

### New in 1.0.0
- Get-S2DStoragePoolInfo — pool capacity, health, resiliency settings, overcommit ratio
- Get-S2DVolumeMap — per-volume resiliency type, pool footprint, infra volume detection
- Get-S2DCacheTierInfo — cache mode, all-flash/all-NVMe detection, software cache
- Get-S2DHealthStatus — 10 health checks (ReserveAdequacy, DiskSymmetry, VolumeHealth,
  DiskHealth, NVMeWear, ThinOvercommit, FirmwareConsistency, RebuildCapacity,
  InfrastructureVolume, CacheTierHealth) with pass/warn/fail and remediation guidance
- Get-S2DCapacityWaterfall — 8-stage capacity accounting from raw physical to final usable
- Invoke-S2DCartographer — one-command orchestrator: connect, collect, report, disconnect
- New-S2DReport — HTML dashboard (Chart.js), Word docx, PDF (headless Edge/Chrome), Excel
- New-S2DDiagram — 6 SVG diagram types: Waterfall, DiskNodeMap, PoolLayout,
  Resiliency, HealthCard, TiBTBReference

### Foundation (unchanged from previews)
- Connect-S2DCluster, Disconnect-S2DCluster
- Get-S2DPhysicalDiskInventory (disk inventory, wear counters, anomaly detection)
- ConvertTo-S2DCapacity, S2DCapacity class (TiB/TB dual-display throughout)
'@
        }
    }
}
