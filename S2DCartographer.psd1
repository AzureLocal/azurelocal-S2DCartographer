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
## v1.3.0 — Thin provisioning risk and what-if capacity modeling

### Added
- **What-if capacity modeling** (`Invoke-S2DCapacityWhatIf`) — model the capacity impact of adding nodes, adding disks per node, replacing disks, or changing resiliency without touching the live cluster. Accepts a JSON snapshot, a piped `S2DClusterData` object, or a live cluster connection. Returns a `S2DWhatIfResult` with baseline and projected waterfalls plus a per-stage delta table. Generates HTML and JSON reports. Closes #27.
- **Thin provisioning risk detection** — `Get-S2DHealthStatus` check 6 (ThinOvercommit) now evaluates max potential pool footprint (Size × data copies for all thin volumes) against pool total at 80% warn / 100% critical thresholds, catching risk before actual overcommit occurs. Closes #44.
- **Check 11: ThinReserveRisk** — new health check evaluates whether maximum thin volume growth would consume the rebuild reserve space, warning before that boundary is crossed.
- `S2DVolume.ThinGrowthHeadroom` and `S2DVolume.MaxPotentialFootprint` properties (S2DCapacity) populated by `Get-S2DVolumeMap` for thin-provisioned volumes.
- Thin Provision Risk KPI card in HTML executive summary dashboard (color-coded at 80% and 100%).
- Growth Headroom and Max Potential Footprint columns in HTML, Word, Excel, and CSV reports for volume map section.
- `Invoke-S2DWaterfallCalculation` private pure function — all 8-stage waterfall math extracted into a session-independent function callable by both `Get-S2DCapacityWaterfall` (live) and `Invoke-S2DCapacityWhatIf` (what-if).

## v1.2.1 — Capacity model correctness fix

### Fixed
- `Get-S2DCapacityWaterfall` Stage 1 now counts only pool-member capacity-tier disks (filtered by `IsPoolMember`). Boot drives (Dell BOSS, HPE M.2 SmartArray) and SAN-presented LUNs no longer inflate Raw Physical, eliminating the false cliff-drop from Stage 1 to Stage 3.
- Stages 7 and 8 are now purely theoretical. Previously they pulled live provisioned-volume data, which caused Stage 8 (Final Usable) to exceed Stage 7 (After Resiliency) on clusters with thin-provisioned volumes, making the pipeline appear to increase. Stage 7 now applies the pool's configured resiliency factor (default: 3-way mirror) to Stage 6 (Available). Stage 8 equals Stage 7 — pipeline terminus.
- `BlendedEfficiencyPercent` on the `S2DCapacityWaterfall` object now reflects the theoretical resiliency efficiency (e.g., 33.3% for 3-way mirror) instead of a live average across provisioned volumes.
- Stage 2 description clarified to explicitly state no bytes are deducted — this stage is a vendor-label informational note only. Closes #43.

## v1.2.0 — Structured data export (JSON/CSV), pool-member filtering, Surveyor cross-link

### Added
- **JSON snapshot export** — every run now writes a structured `S2DClusterData` snapshot as `<base>.json` alongside the existing reports. Stable schema (SchemaVersion 1.0) documented in `docs/schema/cluster-snapshot.md` with a canonical sample at `samples/cluster-snapshot.json`. Enables downstream tools, diffing, what-if calculations, custom scripts. Closes #40.
- **CSV export** — opt-in flat per-collector tables (`-physical-disks.csv`, `-volumes.csv`, `-health-checks.csv`, `-waterfall.csv`) for spreadsheet / Power BI consumers. Request with `-Format Csv`. Closes #40.
- `IsPoolMember` boolean on every disk returned by `Get-S2DPhysicalDiskInventory` — lets downstream tooling distinguish S2D pool members from boot drives and SAN-presented LUNs. Closes #41.
- `-IncludeNonPoolDisks` switch on `Invoke-S2DCartographer` and `New-S2DReport` to override the default filter and show every visible disk. Closes #41.

### Changed
- Physical Disk Inventory tables in HTML, Word, PDF, and Excel reports now show **pool-member disks only** by default. Boot drives and SAN-presented LUNs are filtered because they are not S2D scope and their presence misleads readers of the capacity report. JSON and CSV outputs are unaffected — they always include every disk with an `IsPoolMember` flag for full downstream fidelity. Closes #41.
- `DiskSymmetry`, `DiskHealth`, `NVMeWear`, `FirmwareConsistency`, and `RebuildCapacity` health checks now operate only on pool-member disks. Previously a single asymmetric boot drive could trip the symmetry check; now only actual S2D pool disk counts are compared. Closes #41.
- `Invoke-S2DCartographer -Format All` now includes `Json` in the expansion (HTML + Word + PDF + Excel + JSON).

### Documentation
- Cross-link to Azure Local Surveyor added in README, `docs/index.md`, and the MkDocs Related Projects nav. Closes #35.
- `docs/schema/cluster-snapshot.md` — new file fully documenting the JSON export schema.
- `docs/collectors/physical-disks.md` — new Pool Membership Filter section explaining `IsPoolMember` and the default report filtering behaviour.
- `docs/reports.md` — new JSON Snapshot and CSV Tables sections; format table updated.
- `docs/getting-started.md` — per-run folder listing updated to include the JSON file.

## v1.1.1 — Fix Key Vault and Authentication paths in Invoke-S2DCartographer

### Fixed
- `Invoke-S2DCartographer` parameter splat to `Connect-S2DCluster` no longer forces `ByName` parameter set when `-KeyVaultName` / `-SecretName` are passed. The Key Vault credential path now works end-to-end through the orchestrator — the previous behaviour threw `Credentials are required to connect to cluster` because `-Authentication` was always being splatted in (it lives in `ByName` parameter set only), forcing PowerShell to pick `ByName`. Closes #39.
- `Invoke-S2DCartographer` with `-Credential` + explicit `-Authentication Negotiate` no longer throws the same error. Parameter-set discipline is now strict across all four connection paths (Local / ByCimSession / ByKeyVault / ByName).

### Added
- `Connect-S2DCluster` and `Invoke-S2DCartographer` now accept a `-Username` parameter for the Key Vault credential path. Lets you bypass the ContentType convention when the KV secret does not have that tag populated (common in infra automation that writes secrets without tags).

## v1.1.0 — All formats by default, per-run output folders, session logging

### Added
- **Per-run output folder structure** — each `Invoke-S2DCartographer` run writes to `<OutputDirectory>\<ClusterName>\<yyyyMMdd-HHmm>\`. Multiple clusters and repeated runs never overwrite each other. Diagrams go into a `diagrams\` subfolder within the run folder.
- **Session log file** — a `.log` file is written to the run folder capturing each collection step with duration, warnings, final output paths, overall health, and total run time. A fallback log is written to `OutputDirectory` root if the run fails before the cluster name is known.

### Changed
- `Invoke-S2DCartographer` default `-Format` changed from `Html` to `All` — HTML, Word, PDF, and Excel are all generated unless a specific format is requested.
- `ImportExcel` added to `RequiredModules` — installs automatically from PSGallery alongside S2DCartographer. No manual `Install-Module ImportExcel` step required.
- Pool Allocation Breakdown bar height increased from 90 px to 180 px for better readability.

### Documentation
- `connecting.md` — new **Remoting Prerequisites** section covering WinRM setup, TrustedHosts configuration with FQDN guidance, firewall ports, and the node fan-out flow with a diagram showing how per-node CIM sessions are established.
- `getting-started.md` — updated Quick Start to show per-run folder structure, updated examples to reflect new default format.
- `reports.md` — updated format examples, ImportExcel note, and added output folder structure documentation.

## v1.0.8 — Fix Get-S2DHealthStatus crash on live clusters

### Fixed
- `Get-S2DHealthStatus` now uses `ArrayList` instead of `Generic.List[S2DHealthCheck]`. PowerShell classes dot-sourced in a module fail to resolve as generic type parameters at runtime, causing `.Add()` to throw on live clusters.

## v1.0.7 — HTML report: pool health bar, capacity model, stage descriptions

### Added
- **Storage Pool Health bar** — WAC-style horizontal bar showing volumes used, free space, rebuild reserve (intact in amber / consumed in red hazard stripe), and overcommit (dark red overflow past pool total). Reserve boundary and pool total marked with labeled vertical lines.
- **Pool Allocation Breakdown bar** — stacked bar showing per-volume pool footprint with reserve and overcommit segments.
- **Capacity Model stage descriptions** — table below the capacity chart explaining what each of the 8 stages represents, with delta cost and remaining capacity at each step.
- **Critical Reserve Status KPI** — Reserve Status card in the executive summary now renders with a red background when status is Critical.

### Changed
- HTML report section "Capacity Waterfall" renamed to "Capacity Model" with a subtitle clarifying it is the theoretical S2D best-practice pipeline, not a live utilisation view. Actual state is in the Volume Map and Health Checks.

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
