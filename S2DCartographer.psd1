@{
    RootModule           = 'S2DCartographer.psm1'
    ModuleVersion        = '1.3.0'
    CompatiblePSEditions = @('Core')
    GUID                 = 'c7f4a2d1-83e6-4b19-a05c-9d2e7f318c44'
    Author               = 'Azure Local Cloud'
    CompanyName          = 'countrycloudboy'
    Copyright            = '(c) 2026 Hybrid Cloud Solutions. All rights reserved.'
    Description          = 'Storage Spaces Direct analysis, visualization, and reporting for Azure Local and Windows Server clusters. Inventories physical disks, storage pools, and volumes; computes capacity waterfalls with TiB/TB dual display; generates HTML dashboards, Word documents, PDFs, and Excel workbooks with publication-quality diagrams.'
    PowerShellVersion    = '7.2'
    RequiredModules      = @(
        @{ ModuleName = 'ImportExcel'; ModuleVersion = '7.0.0' }
    )

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
        'Invoke-S2DCapacityWhatIf',
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
            ProjectUri   = 'https://github.com/AzureLocal/azurelocal-s2d-cartographer'
            LicenseUri   = 'https://github.com/AzureLocal/azurelocal-s2d-cartographer/blob/main/LICENSE'
            IconUri      = 'https://raw.githubusercontent.com/AzureLocal/azurelocal-s2d-cartographer/main/docs/assets/images/s2dcartographer-icon.svg'
            ReleaseNotes = @'
## v1.3.1 — Sample output reports
- docs/samples.md added: browse HTML dashboard, overprovisioned HTML, JSON snapshot, what-if HTML report, and what-if JSON result before running the tool. All generated from the MAPROOM IIC synthetic environment.

## v1.3.0 — Thin provisioning risk and what-if capacity modeling
- Invoke-S2DCapacityWhatIf: model AddNodes, AddDisksPerNode, ReplaceDiskSizeTB, ChangeResiliency from JSON snapshot or live cluster. Returns S2DWhatIfResult with before/after waterfalls and per-stage deltas. HTML and JSON reports. Closes #27.
- Check 6 (ThinOvercommit) tiered: Warn >80%, Fail >100% of max potential footprint / pool total. Fires before overcommit occurs. Closes #44.
- Check 11 (ThinReserveRisk): warns when uncommitted thin growth would consume the rebuild reserve.
- S2DVolume.ThinGrowthHeadroom and MaxPotentialFootprint properties for thin volumes.
- Thin Provision Risk KPI in HTML executive summary; Growth Headroom and Max Potential Footprint columns in all report formats.
- Invoke-S2DWaterfallCalculation pure private function extracted from Get-S2DCapacityWaterfall.

## v1.2.1 — Capacity model correctness fix
- Stage 1 counts only pool-member capacity-tier disks (IsPoolMember filter). Closes #43.
- Stages 7 and 8 are now purely theoretical (resiliency factor applied to Stage 6; Stage 8 = Stage 7).
- BlendedEfficiencyPercent reflects theoretical resiliency efficiency.

## v1.2.0 — JSON/CSV export, pool-member filtering, Surveyor cross-link
- JSON snapshot export (SchemaVersion 1.0) on every run. Closes #40.
- CSV export opt-in (-Format Csv). Closes #40.
- IsPoolMember boolean on every physical disk. Closes #41.
- Pool-member-only filtering in HTML/Word/PDF/Excel disk tables by default. Closes #41.

## v1.1.1 — Key Vault and Authentication path fixes. Closes #39.
## v1.1.0 — All formats by default, per-run output folders, session log.
## v1.0.x — Foundation: all 6 collectors, 11 health checks, 4 report formats, 6 SVG diagrams.

Full changelog: https://github.com/AzureLocal/azurelocal-s2d-cartographer/blob/main/CHANGELOG.md
'@
        }
    }
}
