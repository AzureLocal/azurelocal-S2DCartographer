# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to S2DCartographer will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
