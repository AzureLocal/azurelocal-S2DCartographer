# Reports

S2DCartographer generates publication-quality reports from collected cluster data. All formats show TiB and TB side-by-side throughout.

## Formats

| Format | Extension | Use case |
| --- | --- | --- |
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

!!! note "No Office required"
    The Word document is built from scratch using Open XML — compatible with Word 2016+, LibreOffice, and Google Docs. Microsoft Office does not need to be installed on the machine running S2DCartographer.

!!! warning "Garbled XML on open"
    If the generated `.docx` opens with a repair prompt or shows garbled XML, this is usually caused by special characters (em-dashes, Unicode symbols) in cluster or volume names. Please [open an issue](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/new?template=bug_report.yml) with the cluster name and affected volume names.

---

## PDF

Generates HTML first, then uses headless Edge or Chrome to print it to PDF.

**Browser search order:**

1. `msedge.exe` in standard Edge install paths
2. `chrome.exe` in standard Chrome install paths
3. `msedge` / `chrome` / `chromium-browser` on `$env:PATH`

**Generate:**

```powershell
New-S2DReport -InputObject $data -Format Pdf -OutputDirectory "C:\Reports\"
```

!!! note "Browser requirement"
    PDF generation requires Microsoft Edge or Google Chrome. Edge ships pre-installed on Windows 11, Windows Server 2022+, and Azure Local nodes. If no browser is found, the command warns and returns `$null`.

!!! tip "Manual PDF from HTML"
    If no browser is available, generate the HTML report first, then open it in a browser to print manually (Edge/Chrome → Print → Save as PDF).

```powershell
New-S2DReport -InputObject $data -Format Html -OutputDirectory "C:\Reports\"
# Open the .html file in Edge/Chrome → Print → Save as PDF
```

---

## Excel Workbook

Multi-tab `.xlsx` using the [ImportExcel](https://github.com/dfinke/ImportExcel) module.

**Tabs:**

| Tab | Content |
| --- | --- |
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

!!! note "ImportExcel installed automatically"
    `ImportExcel` is declared as a required module in the S2DCartographer manifest. When you install S2DCartographer from PSGallery, `ImportExcel` is installed automatically — no manual step required.

---

## Using `New-S2DReport` directly

`New-S2DReport` requires an `S2DClusterData` object. Obtain one with `-PassThru` on `Invoke-S2DCartographer`, or by building the pipeline manually.

**Parameters:**

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `-InputObject` | `S2DClusterData` | Yes | Cluster data object (also accepts pipeline) |
| `-Format` | `string[]` | Yes | Html, Word, Pdf, Excel, or All |
| `-OutputDirectory` | `string` | No | Destination folder (default: `C:\S2DCartographer`) |
| `-Author` | `string` | No | Author name embedded in report headers |
| `-Company` | `string` | No | Company/org name embedded in report headers |

**Output folder structure:** Each `Invoke-S2DCartographer` run creates a per-run subfolder:

```text
<OutputDirectory>\<ClusterName>\<yyyyMMdd-HHmm>\
  S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.html
  S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.docx
  S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.xlsx
  S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.pdf
  S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.log
  diagrams\
```

Multiple clusters and repeated runs never overwrite each other.

---

## Via `Invoke-S2DCartographer`

The orchestrator handles connect → collect → report → disconnect in one call:

```powershell
# All formats — HTML, Word, PDF, Excel (default — no -Format needed)
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential (Get-Credential)

# All formats + all diagrams
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -IncludeDiagrams `
    -Author "Your Name" -Company "Your Company" `
    -OutputDirectory "C:\Reports\"

# Word + PDF only — customer deliverable
Invoke-S2DCartographer -ClusterName "customer-cluster-01" -Credential $cred `
    -Format Word, Pdf `
    -Author "Kristopher Turner" -Company "Hybrid Cloud Solutions" `
    -OutputDirectory "C:\Deliverables\"

# Key Vault credentials (unattended) — all formats
Invoke-S2DCartographer -ClusterName "c01-prd-bal" `
    -KeyVaultName "kv-platform-prod" -SecretName "cluster-admin-password" `
    -OutputDirectory "C:\AutoReports\"
```
