# Changelog

All notable changes to S2DCartographer will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Pre-release versions start at `0.1.0`. The first stable PSGallery release will be `1.0.0` once Phase 5 is complete.

## [Unreleased]

### Added

- Initial repository scaffold with module manifest, root loader, folder structure, and GitHub Actions CI/CD pipeline.
- `S2DCapacity` class — dual-unit capacity representation with `Bytes`, `TiB`, `TB`, `GiB`, `GB`, and `Display` properties.
- `ConvertTo-S2DCapacity` — converts bytes, TB, or TiB input to a full `S2DCapacity` object with both binary and decimal units.
- `Connect-S2DCluster` — establishes an authenticated CIM/WinRM session to a Failover Cluster with S2D enabled. Supports direct credential, existing `CimSession`, `PSSession`, local execution, and Key Vault credential retrieval.
- `Disconnect-S2DCluster` — tears down the active module session and releases CIM/PS sessions.
- `Get-S2DPhysicalDiskInventory` — inventories all physical disks per node, classifying cache vs capacity role, collecting wear and reliability counters, and detecting symmetry anomalies.
- Pester 5 unit tests: `ConvertTo-S2DCapacity.Tests.ps1`, `Get-S2DReserveCalculation.Tests.ps1`, `Get-S2DResiliencyEfficiency.Tests.ps1`.
- Mock cluster data files for offline/simulation testing: 2-node all-NVMe, 3-node mixed-tier, 4-node three-way mirror, 16-node enterprise.
- MkDocs Material documentation site scaffolding with sections for getting started, collectors, reports, diagrams, TiB vs TB, and capacity math.
- `release-please` configuration for automated changelog and tag management.
