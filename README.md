<p align="center">
  <img src="docs/assets/images/s2dcartographer-banner.svg" alt="S2D Cartographer" width="640"/>
</p>

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PowerShell: 7.x](https://img.shields.io/badge/PowerShell-7.x-3b82f6)](https://github.com/PowerShell/PowerShell)

> *Map your storage. Know your capacity.*

S2DCartographer connects to a live Azure Local or Windows Server cluster, inventories every layer of the Storage Spaces Direct stack, and produces publication-quality capacity analysis, health assessments, and visual diagrams. It answers the questions every S2D administrator actually has: *How much usable space do I really have? Is my reserve adequate? Am I overcommitted?*

---

## The Problem

Storage Spaces Direct is one of the most misunderstood technologies in the Azure Local ecosystem:

- **TiB vs TB** — Drive labels lie. A "1.92 TB" NVMe shows as ~1.75 TiB in Windows. S2DCartographer displays *both units everywhere*.
- **Reserve space** — Most deployments skip it. S2DCartographer measures what you have against what you need.
- **Resiliency overhead** — Three-way mirror uses 33% of raw capacity. S2DCartographer shows the full waterfall.
- **Infrastructure volume blindspot** — Azure Local creates a hidden infrastructure volume. S2DCartographer finds it.
- **No expected vs actual comparison** — Every existing calculator is a planning tool. S2DCartographer scans your live cluster.

---

## What It Does

| Capability | Description |
|------------|-------------|
| **Physical Disk Inventory** | All disks per node: media type, size, firmware, wear, role (cache vs capacity) |
| **Storage Pool Analysis** | Pool health, allocation, reserve adequacy, thin overcommit detection |
| **Volume Map** | All volumes with resiliency type, footprint, provisioning type, efficiency |
| **Cache Tier Analysis** | Cache configuration, binding ratio, degradation detection |
| **Health Checks** | 10+ pass/fail checks with remediation guidance |
| **Capacity Waterfall** | 8-stage math from raw physical to final usable capacity |
| **Reports** | HTML, Word, PDF, and Excel formats suitable for customer deliverables |
| **Diagrams** | Capacity waterfall, disk-to-node map, pool layout, resiliency diagrams |
| **TiB/TB everywhere** | Dual-unit display on every value in every output |

---

## Installation

### From source (current)

```powershell
git clone https://github.com/AzureLocal/azurelocal-S2DCartographer.git
Set-Location .\azurelocal-S2DCartographer
Import-Module .\S2DCartographer.psd1 -Force
```

### From PSGallery (preview)

```powershell
Install-Module S2DCartographer -RequiredVersion 0.1.0-preview1 -AllowPrerelease
```

The preview package intentionally exposes only the implemented Phase 1 commands:
`Connect-S2DCluster`, `Disconnect-S2DCluster`, `Get-S2DPhysicalDiskInventory`, and `ConvertTo-S2DCapacity`.

---

## Quick Start

```powershell
# Connect to your cluster
Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential (Get-Credential)

# Run a quick health check
Get-S2DHealthStatus | Format-Table CheckName, Severity, Status, Details

# Get the full capacity waterfall
Get-S2DCapacityWaterfall | Format-List

# Generate a full HTML report
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -Format Html -OutputDirectory "C:\Reports\"
```

---

## Commands

| Command | Purpose |
|---------|---------|
| `Connect-S2DCluster` | Establish authenticated session to a cluster |
| `Disconnect-S2DCluster` | Clean up the active session |
| `Get-S2DPhysicalDiskInventory` | Inventory all physical disks with health and wear data |
| `ConvertTo-S2DCapacity` | Convert bytes/TB/TiB to dual-unit capacity object |

The remaining collectors, reporting, diagramming, and orchestration commands remain in development and are planned for later milestones.

---

## Development Status

| Phase | Work | Status |
|-------|------|--------|
| Phase 1 | Foundation: module scaffold, connection, ConvertTo-S2DCapacity, disk inventory | 🔄 In Progress |
| Phase 2 | Core collectors: pool, volumes, cache, waterfall, health | ⏳ Planned |
| Phase 3 | Reporting engine: HTML, Excel, Word, PDF | ⏳ Planned |
| Phase 4 | Diagrams: SVG waterfall, disk-node map, pool layout | ⏳ Planned |
| Phase 5 | Orchestrator, Key Vault, MkDocs, PSGallery publish | ⏳ Planned |

---

## License

[MIT](LICENSE) — (c) 2026 Kristopher Turner / Hybrid Cloud Solutions, LLC
