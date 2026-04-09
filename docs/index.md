# S2DCartographer

Welcome to **S2DCartographer** — the Storage Spaces Direct analysis, visualization, and reporting tool for Azure Local and Windows Server clusters.

## What Is This?

S2DCartographer scans a live cluster and maps your entire S2D storage stack — from raw physical disks through the resiliency layers all the way down to actual usable VM capacity. It renders what you find into publication-quality HTML, Word, PDF, and Excel reports, with SVG diagrams for every stage.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Capacity waterfall** | 8 stages from raw physical to final usable capacity |
| **TiB/TB dual-display** | Every capacity value shows both binary and decimal units |
| **Reserve validation** | Live comparison of actual vs. recommended reserve space |
| **Health assessments** | 10+ pass/fail checks with remediation guidance |
| **Reports** | HTML, Word, PDF, Excel — ready for customer deliverables |
| **Diagrams** | SVG waterfall, disk-node map, pool layout, resiliency views |

## Quick Start

```powershell
Import-Module S2DCartographer

Connect-S2DCluster -ClusterName "my-cluster" -Credential (Get-Credential)
Get-S2DPhysicalDiskInventory | Format-Table NodeName, FriendlyName, Role, Size
```

## Navigation

- **[Getting Started](getting-started.md)** — Prerequisites, installation, first run
- **[TiB vs TB](tib-vs-tb.md)** — Why the numbers don't match your drive labels
- **[Capacity Math](capacity-math.md)** — How the 8-stage waterfall is computed
- **[Collectors](collectors.md)** — What each collector gathers and from where
- **[Reports](reports.md)** — Report formats, templates, and output options
- **[Diagrams](diagrams.md)** — Available diagram types and generation options
