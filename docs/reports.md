# Reports

S2DCartographer generates publication-quality reports from collected cluster data. All formats show TiB and TB side-by-side throughout.

## Formats

| Format | Extension | Use case |
| -------- | ----------- | ---------- |
| **HTML** | `.html` | Interactive browser dashboard; self-contained, no dependencies |
| **Word** | `.docx` | Customer deliverables, architecture review documents |
| **PDF** | `.pdf` | Archivable, printable, universally readable |
| **Excel** | `.xlsx` | Data analysis, capacity tracking over time |
| **All** | — | Generates all four formats in one call |

---

## HTML Dashboard

Self-contained single-file HTML with embedded CSS and Chart.js 4.4.0. No internet connection required — all assets are inlined.

**Sections:**

- **Executive Summary** — cluster name, node count, overall health badge (green/yellow/red), collection timestamp
- **Capacity Waterfall** — interactive horizontal bar chart (Chart.js) showing all 8 stages with values
- **TiB/TB Toggle** — switch in the toolbar flips all capacity values between TiB and TB simultaneously
- **Physical Disk Inventory** — table with node, model, media type, role, capacity, wear %, health
- **Storage Pool** — total/allocated/remaining capacity, overcommit ratio
- **Volume Map** — per-volume resiliency, footprint, efficiency %, infra flag
- **Health Checks** — traffic-light cards per check with Details and Remediation text
- **TiB/TB Reference** — conversion table for common NVMe/SSD drive sizes

**Generate:**

```powershell
$data = Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred -PassThru
New-S2DReport -InputObject $data -Format Html -OutputDirectory "C:\Reports\"
```

---

## Word Document

Pure PowerShell `.docx` — no Microsoft Office or COM automation required. Uses `System.IO.Compression.ZipArchive` to generate Open XML directly.

**Sections:**

- Title page with cluster name, author, company, and collection date
- Executive Summary — health status, key capacity metrics
- Capacity Waterfall — 8-stage table
- Physical Disk Inventory — full table with all disk fields
- Volume Map — per-volume resiliency and capacity
- Health Assessment — all 10 checks with severity-coded status and remediation guidance
- Appendix A: TiB vs TB Explanation
- Appendix B: S2D Reserve Space Best Practices

**Generate:**

```powershell
New-S2DReport -InputObject $data -Format Word `
    -Author "Kristopher Turner" -Company "TierPoint" `
    -OutputDirectory "C:\Deliverables\"
```

**No Office required:** The Word document is built from scratch using Open XML — compatible with Word 2016+, LibreOffice, and Google Docs.

---

## PDF

Generates HTML first, then uses headless Edge or Chrome to print it to PDF.

**Browser search order:**

1. `msedge.exe` in standard Edge install paths
2. `chrome.exe` in standard Chrome install paths
3. `msedge` / `chrome` / `chromium-browser` on `$env:PATH`

If no browser is found, `Export-S2DPdfReport` writes a warning with manual instructions and returns `$null`.

**Generate:**

```powershell
New-S2DReport -InputObject $data -Format Pdf -OutputDirectory "C:\Reports\"
```

**Tip:** For scheduled/unattended runs, ensure Edge is installed on the machine running S2DCartographer. Edge ships with Windows 11 and Windows Server 2022+ by default.

---

## Excel Workbook

Multi-tab `.xlsx` using the [ImportExcel](https://github.com/dfinke/ImportExcel) module. Install once with `Install-Module ImportExcel`.

**Tabs:**

| Tab | Content |
| ----- | --------- |
| **Summary** | Cluster name, node count, health status, collection date, key capacity metrics |
| **Capacity Waterfall** | All 8 stages with TiB and TB columns |
| **Physical Disks** | Full disk inventory — node, model, media type, role, capacity, wear %, firmware |
| **Storage Pool** | Pool name, health, total/allocated/remaining, overcommit ratio, resiliency settings |
| **Volumes** | All volumes — resiliency, copies, provisioning type, size, footprint, efficiency |
| **Health Checks** | All 10 checks — name, severity, status, details, remediation |
| **Metadata** | Module version, collection timestamp, cluster FQDN, node list |

**Generate:**

```powershell
New-S2DReport -InputObject $data -Format Excel -OutputDirectory "C:\Reports\"
```

---

## Using `New-S2DReport` directly

`New-S2DReport` requires an `S2DClusterData` object. Obtain one with `-PassThru` on `Invoke-S2DCartographer`, or by building the pipeline manually.

**Parameters:**

| Parameter | Type | Required | Description |
| ----------- | ------ | ---------- | ------------- |
| `-InputObject` | `S2DClusterData` | Yes | Cluster data object (also accepts pipeline) |
| `-Format` | `string[]` | Yes | Html, Word, Pdf, Excel, or All |
| `-OutputDirectory` | `string` | No | Destination folder (default: `C:\S2DCartographer`) |
| `-Author` | `string` | No | Author name embedded in report headers |
| `-Company` | `string` | No | Company/org name embedded in report headers |

**Output file naming:** `S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.<ext>`

---

## Via `Invoke-S2DCartographer`

The orchestrator handles connect → collect → report → disconnect in one call:

```powershell
# HTML only (default)
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential (Get-Credential)

# All formats + all diagrams
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -Format All -IncludeDiagrams `
    -Author "Your Name" -Company "Your Company" `
    -OutputDirectory "C:\Reports\2026-04-11-c01-prd-bal\"

# Word + PDF customer deliverable
Invoke-S2DCartographer -ClusterName "customer-cluster-01" -Credential $cred `
    -Format Word, Pdf `
    -Author "Kristopher Turner" -Company "Hybrid Cloud Solutions" `
    -OutputDirectory "C:\Deliverables\Customer\"

# Key Vault credentials (unattended)
Invoke-S2DCartographer -ClusterName "c01-prd-bal" `
    -KeyVaultName "kv-platform-prod" -SecretName "cluster-admin-password" `
    -Format Html -OutputDirectory "C:\AutoReports\"
```
