# Reports

**Status: Planned (Phase 3)**

S2DCartographer will generate publication-quality reports from collected cluster data. All formats include TiB/TB dual-display throughout.

## Formats

| Format | Cmdlet flag | Use case |
|--------|-------------|---------|
| **HTML** | `-Format Html` | Interactive dashboard, shareable via browser, no software required |
| **Word** | `-Format Word` | Customer deliverables, architecture review documents |
| **PDF** | `-Format Pdf` | Universally readable, archivable, printable |
| **Excel** | `-Format Excel` | Data analysis, capacity tracking over time |
| **All** | `-Format All` | Generate all formats in one run |

## HTML Dashboard

Self-contained single-file HTML with embedded CSS and Chart.js:

- Executive summary with health score (green/yellow/red)
- Interactive capacity waterfall chart
- Disk inventory table (sortable, filterable)
- Storage pool utilization gauge
- Volume map with resiliency type and provisioning detail
- Health checks pass/fail cards with remediation guidance
- TiB/TB toggle switch
- Print-to-PDF and copy-to-clipboard buttons

## Word Document

Professional `.docx` with cover page, table of contents, and all report sections:

- Embedded SVG waterfall diagram
- Formatted disk inventory tables
- Health assessment with severity-coded findings
- Appendix A: TiB vs TB Explanation
- Appendix B: S2D Reserve Space Best Practices

## Excel Workbook

Multi-tab `.xlsx` using the ImportExcel module:

| Tab | Content |
|-----|---------|
| Summary | Key metrics, health score |
| Capacity Waterfall | Waterfall stages with embedded chart |
| Physical Disks | Full disk inventory |
| Storage Pool | Pool configuration and utilization |
| Volumes | All volumes with resiliency and provisioning |
| Health Checks | Pass/fail results |
| Raw Data | Complete JSON export |

## Usage

```powershell
# Single format
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -Format Html -OutputDirectory "C:\Reports\"

# All formats at once
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -Format All -OutputDirectory "C:\Reports\2026-04-09-c01-prd-bal\"

# Customer-ready Word and PDF with author info
Invoke-S2DCartographer -ClusterName "customer-cluster-01" -Credential $cred `
    -Format Word, Pdf `
    -Author "Kristopher Turner" -Company "Hybrid Cloud Solutions, LLC" `
    -OutputDirectory "C:\Deliverables\Customer\"
```
