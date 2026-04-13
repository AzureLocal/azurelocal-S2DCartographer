# S2DCartographer

![S2D Cartographer](assets/images/s2dcartographer-banner.svg)

Welcome to **S2DCartographer** — the Storage Spaces Direct analysis, visualization, and reporting tool for Azure Local and Windows Server clusters.

!!! tip "Planning a new cluster?"
    Use **[Azure Local Surveyor](https://azurelocal.github.io/azurelocal-surveyor)** to model capacity, compute, and workloads *before* you deploy. Run S2DCartographer on the running cluster to validate what was actually built. **Surveyor plans; Cartographer verifies.**

---

## What Is This?

S2DCartographer scans a live cluster and maps your entire S2D storage stack — from raw physical disks through the resiliency layers all the way down to actual usable VM capacity. It renders what you find into publication-quality HTML, Word, PDF, and Excel reports, SVG diagrams for every stage, and a structured JSON snapshot for downstream tooling.

---

## Key Capabilities

| Capability | Description |
| --- | --- |
| **Capacity waterfall** | 8 stages from raw physical to final usable capacity |
| **TiB/TB dual-display** | Every capacity value shows both binary and decimal units |
| **Reserve validation** | Live comparison of actual vs. recommended reserve space |
| **Health assessments** | 10 pass/fail checks with remediation guidance |
| **Reports** | HTML, Word, PDF, Excel — ready for customer deliverables |
| **Data export** | JSON snapshot + per-collector CSVs for downstream tooling |
| **Diagrams** | SVG waterfall, disk-node map, pool layout, resiliency views |

---

## Quick Start

```powershell
# Install from PSGallery
Install-Module S2DCartographer -Scope CurrentUser

# Connect and run everything in one command
Import-Module S2DCartographer
Invoke-S2DCartographer -ClusterName "my-cluster" -Credential (Get-Credential) -Format Html -OutputDirectory "C:\Reports\"
```

---

## Navigation

- **[Getting Started](getting-started.md)** — Prerequisites, installation, first run
- **[Connecting](connecting.md)** — Domain-joined, non-domain, local node, and Key Vault connection scenarios
- **[Collectors](collectors.md)** — What each collector gathers and from where
- **[Reports](reports.md)** — Report formats, templates, and output options
- **[Diagrams](diagrams.md)** — Available diagram types and generation options
- **[Concepts: TiB vs TB](tib-vs-tb.md)** — Why the numbers don't match your drive labels
- **[Concepts: Capacity Math](capacity-math.md)** — How the 8-stage waterfall is computed
- **[Concepts: Architecture](concepts/architecture.md)** — Pipeline design and session cache
- **[Troubleshooting](project/troubleshooting.md)** — Common issues and fixes
- **[Roadmap](project/roadmap.md)** — What's coming next
