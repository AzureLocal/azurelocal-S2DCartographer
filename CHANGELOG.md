# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to S2DCartographer will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] — 2026-04-13

### Added

- **JSON snapshot export** — every run writes a structured `S2DClusterData` snapshot as `<base>.json` alongside the existing reports. Stable schema at SchemaVersion 1.0, documented in `docs/schema/cluster-snapshot.md` with a canonical sample at `samples/cluster-snapshot.json`. Enables downstream tools, diff workflows, what-if calculations, external dashboards, custom scripts. Closes [#40](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/40).
- **CSV export** — opt-in flat per-collector tables (`-physical-disks.csv`, `-volumes.csv`, `-health-checks.csv`, `-waterfall.csv`) for spreadsheet / Power BI consumers. Request with `-Format Csv`. Closes [#40](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/40).
- `IsPoolMember` boolean on every disk returned by `Get-S2DPhysicalDiskInventory`. Lets downstream tooling distinguish S2D pool members from boot drives and SAN-presented LUNs. Closes [#41](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/41).
- `-IncludeNonPoolDisks` switch on `Invoke-S2DCartographer` and `New-S2DReport` for when you explicitly want every disk in the rendered report, not just pool members. Closes [#41](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/41).

### Changed

- Physical Disk Inventory tables in HTML, Word, PDF, and Excel reports now show **pool-member disks only** by default. Boot drives (Dell BOSS, HPE M.2 SmartArray) and SAN-presented LUNs are filtered because they are not S2D scope and their presence in the table misleads readers. JSON and CSV exports always include every disk with an `IsPoolMember` flag. Closes [#41](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/41).
- `DiskSymmetry`, `DiskHealth`, `NVMeWear`, `FirmwareConsistency`, and `RebuildCapacity` health checks now operate only on pool-member disks. Previously a single asymmetric boot drive could trip the symmetry check; now only actual S2D pool disk counts are compared, eliminating false positives on heterogeneous hardware. Closes [#41](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/41).
- `Invoke-S2DCartographer -Format All` now includes `Json` in the expansion (HTML + Word + PDF + Excel + JSON). CSV remains opt-in because it produces multiple files per run.

### Documentation

- Cross-link to Azure Local Surveyor added in README, `docs/index.md`, and the MkDocs "Related Projects" nav entry. Surveyor plans; Cartographer verifies. Closes [#35](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/35).
- `docs/schema/cluster-snapshot.md` — new page documenting every field of the JSON export, including `S2DCapacity` shape, PowerShell / jq / Python consumption examples, and schema versioning policy.
- `docs/collectors/physical-disks.md` — new Pool Membership Filter section; new `IsPoolMember` property row in the output field table.
- `docs/reports.md` — new JSON Snapshot and CSV Tables sections; Formats table updated; `-IncludeNonPoolDisks` documented in the parameter table; per-run folder listing updated to include the `.json` file.
- `docs/getting-started.md` — per-run folder listing updated to include the JSON file.
- `samples/cluster-snapshot.json` — canonical JSON sample committed, generated from the MAPROOM IIC fixture. Closes [#42](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/42).

## [1.1.1] — 2026-04-13

### Fixed

- `Invoke-S2DCartographer` parameter splat to `Connect-S2DCluster` no longer forces the `ByName` parameter set when `-KeyVaultName` / `-SecretName` are passed. The Key Vault credential path now works end-to-end through the orchestrator. Previous behaviour threw `Credentials are required to connect to cluster` because `-Authentication` was always being splatted in (it lives in `ByName` only), forcing PowerShell parameter-set resolution to pick `ByName` and then demanding a `-Credential` that was never supplied. Closes [#39](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/39).
- `Invoke-S2DCartographer` with `-Credential` + explicit `-Authentication Negotiate` no longer throws the same error. Parameter-set discipline is now strict across all four connection paths (`Local`, `ByCimSession`, `ByKeyVault`, `ByName`).

### Added

- `Connect-S2DCluster` and `Invoke-S2DCartographer` now accept a `-Username` parameter for the Key Vault credential path. Lets callers bypass the ContentType tag convention when the KV secret does not have that tag populated — common in infra automation pipelines that write the secret value without also writing the username to ContentType.

## [1.1.0] — 2026-04-13

### Added

- **Per-run output folder structure** — each `Invoke-S2DCartographer` run writes to `<OutputDirectory>\<ClusterName>\<yyyyMMdd-HHmm>\`. Multiple clusters and repeated runs never overwrite each other. Diagrams go into a `diagrams\` subfolder within the run folder. Closes [#37](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/37).
- **Session log file** — a `.log` file is written to the run folder capturing each collection step with duration, warnings, final output paths, overall health, and total run time. A fallback log is written to `OutputDirectory` root if the run fails before the cluster name is known. Closes [#37](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/37).

### Changed

- `Invoke-S2DCartographer` default `-Format` changed from `Html` to `All` — HTML, Word, PDF, and Excel are all generated unless a specific format is requested. Closes [#36](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/36).
- `ImportExcel` added to `RequiredModules` in the module manifest — installs automatically from PSGallery. No manual `Install-Module ImportExcel` step required. Closes [#36](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/36).
- Pool Allocation Breakdown bar height increased from 90 px to 180 px for improved readability. Closes [#38](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/38).

### Documentation

- `connecting.md` — new **Remoting Prerequisites** section covering WinRM setup, TrustedHosts configuration with FQDN guidance, firewall ports table, and the node fan-out flow diagram showing how per-node CIM sessions are established and how auth is inherited. Closes [#34](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/34).
- `getting-started.md` — updated Quick Start to show per-run folder structure, ImportExcel auto-install note, updated examples to reflect `All` as the default format.
- `reports.md` — updated format examples, ImportExcel dependency note, output folder structure documentation.

## [1.0.8] — 2026-04-13

### Fixed

- `Get-S2DHealthStatus` — replaced `[System.Collections.Generic.List[S2DHealthCheck]]` with `[System.Collections.ArrayList]`. PowerShell classes defined via dot-sourcing can fail to resolve as generic type parameters at runtime, causing `.Add()` to throw "Cannot find an overload for 'Add' and the argument count: '1'" when running against a live cluster.

## [1.0.7] — 2026-04-13

### Added

- **Storage Pool Health bar** — WAC-style horizontal bar showing volumes used (blue), free space (green), rebuild reserve intact (amber), reserve consumed (red hazard stripe), and overcommit beyond pool total (dark red). Reserve boundary and pool total marked with labeled vertical lines.
- **Pool Allocation Breakdown bar** — stacked bar showing per-volume pool footprint with reserve and overcommit segments.
- **Capacity Model stage descriptions** — table beneath the capacity chart explaining what each of the 8 stages represents, with delta cost and remaining capacity per step. Descriptions sourced from waterfall stage objects so live cluster data populates them automatically.
- **Critical Reserve Status KPI** — Reserve Status card in the executive summary now renders with red background and text when status is `Critical`.

### Changed

- HTML report section "Capacity Waterfall" renamed to **"Capacity Model"** with subtitle clarifying it is the theoretical S2D best-practice pipeline, not a live utilisation view. Actual state is reflected in the Volume Map and Health Checks sections.

### Fixed

- `Show-S2DOverprovisionedReport.ps1` — replaced hardcoded `using module` with runtime dot-source of class files so the script runs correctly from any working directory without requiring module type export.

## [1.0.6] — 2026-04-12

### Fixed

- `Connect-S2DCluster`: short cluster name resolution now checks `TrustedHosts` first and promotes the short name to a matching FQDN entry (e.g. `tplabs-clus01` → `tplabs-clus01.azrl.mgmt`). On workgroup / non-domain-joined hosts, DNS suffix search lists for internal AD domains are usually absent, so the 1.0.5 DNS-only resolver silently fell through to the short name and produced `0x8009030e`. `TrustedHosts` is authoritative on these hosts and already reflects what WinRM will accept.
- Resolution order is now: TrustedHosts → DNS (`GetHostEntry`) → short name pass-through → precise remediation error.

### Changed

- `Connect-S2DCluster` credential prompt message now includes the accepted username formats (`DOMAIN\user` or `user@fqdn.domain`) and explicitly notes that a plain local username will not authenticate against a domain cluster. Renders directly in the `Get-Credential` dialog.

## [1.0.5] — 2026-04-12

### Fixed

- `Connect-S2DCluster`: when the caller supplies a short cluster name (e.g. `tplabs-clus01` instead of `tplabs-clus01.azrl.mgmt`), the cmdlet now resolves the short name to a FQDN via DNS before opening the CIM session. Workgroup and non-domain-joined hosts typically have `TrustedHosts` configured with FQDNs, so a short-name target would previously fail with `0x8009030e` at `New-CimSession` even with correct credentials. The resolved FQDN is stored in `$Script:S2DSession.ClusterFqdn`.
- `Connect-S2DCluster`: `New-CimSession` failures in the `ByName` path are now caught and rethrown with a multi-line remediation message that calls out the four most common causes — TrustedHosts missing the cluster FQDN, wrong credentials, short-name DNS failure, and `-Local` as an alternative — instead of surfacing the raw WinRM exception. The message also reports whether the host is domain-joined, which is the usual trigger.

## [1.0.4] — 2026-04-12

### Fixed

- `Connect-S2DCluster`: when `-Credential` is not supplied in the `ByName` parameter set, the cmdlet now prompts interactively via `Get-Credential` instead of silently falling through to `New-CimSession` with the current logged-on user context — which almost always fails on workgroup or cross-domain hosts with a cryptic "Access is denied". Callers running non-interactively must supply `-Credential`, use `-Local`, or pass a prebuilt `-CimSession`/`-PSSession`.

## [1.0.3] — 2026-04-12

### Fixed

- **Workgroup / non-domain-joined fan-out failure** — `Connect-S2DCluster` now resolves each enumerated short node name to a fully qualified target (via the cluster FQDN suffix, falling back to DNS) and stores the mapping in `$Script:S2DSession.NodeTargets`. `Get-S2DPhysicalDiskInventory` opens per-node CIM sessions against the FQDN target instead of the short name, which matches typical `TrustedHosts` configuration on workgroup management hosts. Closes [#33](https://github.com/AzureLocal/azurelocal-S2DCartographer/issues/33).
- **Preflight validation** — after cluster connect, `Connect-S2DCluster` now test-opens a CIM session against the first resolved node target. If it fails, the cmdlet throws one precise error listing the node FQDNs and three concrete remediations (domain-joined host, `-Local` mode, or TrustedHosts configuration) instead of letting N generic WinRM warnings fall out of the per-collector fan-out path.

### Added

- `Resolve-S2DNodeFqdn` (private) — deterministic helper that converts a short node name to an FQDN using cluster suffix append → DNS lookup → short-name fallback. Unit-tested offline.

## [1.0.2] — 2026-04-11

### Fixed

- `Get-S2DPhysicalDiskInventory`: per-node CIM sessions now inherit Authentication method and Credential from the module session, fixing WinRM Kerberos failures on non-domain-joined or cross-domain clients — completes [#31](https://github.com/AzureLocal/azurelocal-S2DCartographer/issues/31).
- `Connect-S2DCluster`: `ByKeyVault` parameter set now passes `-Authentication Negotiate` to `New-CimSession` instead of relying on the Kerberos default.
- `Invoke-S2DCartographer`: add `-Authentication` parameter that passes through to `Connect-S2DCluster`.
- Module session state (`$Script:S2DSession`) now stores `Authentication` and `Credential` so downstream collectors can create per-node CIM sessions with the same auth settings.

## [1.0.1] — 2026-04-11

### Fixed

- `Connect-S2DCluster`: add `-Authentication` parameter (default: `Negotiate`) to `New-CimSession`. Fixes WinRM Kerberos failure on non-domain-joined or cross-domain clients — closes [#31](https://github.com/AzureLocal/azurelocal-S2DCartographer/issues/31).

## [1.0.0] — 2026-04-11

### Added

- `Get-S2DStoragePoolInfo` — pool capacity, health, resiliency settings, storage tiers, overcommit ratio.
- `Get-S2DVolumeMap` — per-volume resiliency type, pool footprint, efficiency %, provisioning type, infrastructure volume detection.
- `Get-S2DCacheTierInfo` — cache mode, all-flash/all-NVMe detection, software write-back cache identification.
- `Get-S2DHealthStatus` — 10 health checks (ReserveAdequacy, DiskSymmetry, VolumeHealth, DiskHealth, NVMeWear, ThinOvercommit, FirmwareConsistency, RebuildCapacity, InfrastructureVolume, CacheTierHealth) with pass/warn/fail and remediation guidance.
- `Get-S2DCapacityWaterfall` — 8-stage capacity accounting pipeline from raw physical to final usable VM space.
- `Invoke-S2DCartographer` — one-command orchestrator: connect → collect → report → disconnect. Supports all report formats, diagram types, Key Vault credentials, and `-PassThru`.
- `New-S2DReport` — HTML (Chart.js dashboard), Word (.docx, no Office required), PDF (headless Edge/Chrome), and Excel (.xlsx via ImportExcel).
- `New-S2DDiagram` — 6 SVG diagram types: Waterfall, DiskNodeMap, PoolLayout, Resiliency, HealthCard, TiBTBReference.
- 119 Pester 5 unit tests across all collectors, capacity math, and health checks.
- Complete MkDocs documentation site: getting-started, collectors, reports, diagrams, capacity-math, tib-vs-tb.
- Sample output files: `samples/sample-waterfall.svg`, `samples/sample-html-report.html`.

### Changed

- Minimum PowerShell version raised to 7.2 (was 7.0).
- `ProjectUri` updated to point to the GitHub repository.

## [0.1.0-preview2] — 2026-03-28

### Fixed

- `Connect-S2DCluster` failing on non-domain-joined management machines. S2D validation now uses `Get-StoragePool` via CIM instead of `Get-ClusterS2D`.
- Cluster node discovery switched to `MSCluster_Node` CIM class via remote session instead of `Get-ClusterNode` (which required local RSAT).

## [0.1.0-preview1] — 2026-03-15

### Features

- Initial repository scaffold, module manifest, folder structure, GitHub Actions CI/CD.
- `S2DCapacity` class — dual-unit capacity with `Bytes`, `TiB`, `TB`, `GiB`, `GB`, `Display`.
- `ConvertTo-S2DCapacity` — converts bytes, TB, or TiB to `S2DCapacity`.
- `Connect-S2DCluster`, `Disconnect-S2DCluster`.
- `Get-S2DPhysicalDiskInventory`.
- Pester 5 unit tests for capacity math and reserve calculation.
- MkDocs Material documentation site scaffolding.
- `release-please` configuration.
