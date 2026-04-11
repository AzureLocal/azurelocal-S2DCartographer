# Changelog

All notable changes to S2DCartographer will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1](https://github.com/AzureLocal/azurelocal-S2DCartographer/compare/v0.1.0...v0.1.1) (2026-04-11)


### Features

* align repo structure to AzureLocal org standards ([a458f17](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/a458f17e840310fd06561a60cfd7fc01690e6adb))
* **brand:** add S2D Cartographer icon and banner SVGs ([a902970](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/a9029704e577d1266d3788ab825e73785a6428e8))
* implement Get-S2DPhysicalDiskInventory collector — closes [#3](https://github.com/AzureLocal/azurelocal-S2DCartographer/issues/3) ([6c92185](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/6c92185a3844e55db1275d6c81e0f2321489c2e9))
* implement v1.0.0 — all collectors, reports, diagrams, orchestrator, and unit tests ([ff3cc93](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/ff3cc9379eaf4e35514b37db26b2e2091cac77bf))


### Bug Fixes

* add -Authentication parameter to Connect-S2DCluster, default Negotiate ([3221d3f](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/3221d3f855c48007a118e1073b6a664341d1c0d1)), closes [#31](https://github.com/AzureLocal/azurelocal-S2DCartographer/issues/31)
* add validate-repo-structure.yml per org standard; fix mkdocs theme to blue/teal ([65236e9](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/65236e9b01a19786ef55b3b304cfe04e4639c1dd))
* Connect-S2DCluster non-domain-joined compatibility — replace Get-ClusterS2D with CIM StoragePool check, node discovery via MSCluster_Node ([5604a9b](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/5604a9bc0d546f435e5f29fabc030b06204bf791))
* use string form of OutputType for S2DCapacity; add maproom test fixtures and unit tests ([8d52300](https://github.com/AzureLocal/azurelocal-S2DCartographer/commit/8d523001c288b3d4200b0445a1fd6714d1bcb5ef))

## [Unreleased]

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
