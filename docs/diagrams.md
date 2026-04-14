# Diagrams

S2DCartographer generates SVG diagrams for embedding in reports, documentation, and presentations. All diagrams are self-contained SVG files — no external fonts or assets required.

## Diagram Types

### Capacity Waterfall — `Waterfall`

Horizontal bar diagram showing all 7 stages of capacity consumption. Each stage shows the cumulative remaining capacity with a delta arrow for the deduction at that stage. Status color-coding: green (OK), amber (Warning), red (Critical).

```text
Stage 1  Raw Physical         ████████████████████████████████████  55.88 TiB
Stage 2  Vendor Label (TB)    ████████████████████████████████████  55.88 TiB  (61.44 TB)
Stage 3  After Pool Overhead  ████████████████████████████████████  55.58 TiB  − 0.30 TiB
Stage 4  After Reserve        ██████████████████████████████        41.61 TiB  −13.97 TiB  ⚠
Stage 5  After Infra Volume   ██████████████████████████████        41.36 TiB  − 0.25 TiB
Stage 6  Available            ██████████████████████████████        41.36 TiB
Stage 7  After Resiliency     ██████████                            13.79 TiB  −27.58 TiB
Stage 7  Usable Capacity    ██████████                            13.97 TiB
```

### Disk-to-Node Map — `DiskNodeMap`

One box per cluster node containing all physical disks as colored cells:

- **Blue** — cache-tier disk (Journal)
- **Green** — capacity-tier disk (Auto-Select)
- **Amber** — degraded or warning health
- **Red** — failed or unknown health

Disk model and size are labeled. Node names appear above each box. Useful for visualizing asymmetric configurations or identifying which node has failed drives.

### Storage Pool Layout — `PoolLayout`

Stacked horizontal bar showing how the pool is allocated:

- Infrastructure volume footprint (grey)
- Reserve space (amber)
- Workload volume footprints, one segment per volume (blue shades)
- Free pool space (green)

TiB and TB values are labeled on each segment. Overcommitted segments are highlighted.

### Volume Resiliency — `Resiliency`

Per-volume table diagram showing:

- Volume name
- Resiliency type label (Three-Way Mirror, Two-Way Mirror, Dual Parity, etc.)
- Logical size vs pool footprint
- Efficiency percentage
- Infrastructure volume flag

Volumes are sorted by footprint (largest first). The blended cluster efficiency is shown at the bottom.

### Health Scorecard — `HealthCard`

Traffic-light grid — one card per health check:

- **Green** — Pass
- **Amber** — Warn
- **Red** — Fail / Critical
- **Grey** — Not evaluated

Each card shows the check name, status label, and a one-line summary. The overall health badge (Healthy / Warning / Critical) is displayed prominently at the top.

### TiB/TB Reference — `TiBTBReference`

Conversion reference table for common NVMe and SSD drive sizes, showing vendor TB label alongside the actual TiB value Windows reports. Includes the gap percentage. Useful for quickly reading drive specs without manual math.

---

## Usage

### Via `New-S2DDiagram`

```powershell
$data = Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred -PassThru

# All 6 diagrams
New-S2DDiagram -InputObject $data -DiagramType All -OutputDirectory "C:\Reports\"

# Specific types
New-S2DDiagram -InputObject $data -DiagramType Waterfall, HealthCard -OutputDirectory "C:\Reports\"

# Pipeline
$data | New-S2DDiagram -DiagramType DiskNodeMap
```

**Parameters:**

| Parameter | Type | Description |
| ----------- | ------ | ------------- |
| `-InputObject` | `S2DClusterData` | Cluster data object (accepts pipeline) |
| `-DiagramType` | `string[]` | Waterfall, DiskNodeMap, PoolLayout, Resiliency, HealthCard, TiBTBReference, or All |
| `-OutputDirectory` | `string` | Destination folder (default: `C:\S2DCartographer`) |

**Output file naming:** `<ClusterName>_<DiagramType>_<yyyyMMdd-HHmm>.svg`

### Via `Invoke-S2DCartographer`

Use `-IncludeDiagrams` to generate all 6 diagram types as part of the full pipeline:

```powershell
Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred `
    -Format Html -IncludeDiagrams -OutputDirectory "C:\Reports\"
```

---

## Embedding SVGs

SVG files can be embedded directly in Markdown, HTML, or Word documents.

**In HTML:**

```html
<img src="cluster_Waterfall_20260411-1430.svg" alt="Capacity Waterfall" width="900">
```

**In Markdown (GitHub/MkDocs):**

```markdown
![Capacity Waterfall](samples/sample-waterfall.svg)
```

**In PowerPoint:** Insert → Pictures → SVG. Scales without quality loss.

**In Word:** Insert → Pictures → SVG, or embedded automatically by `New-S2DReport -Format Word` when `-IncludeDiagrams` was used on `Invoke-S2DCartographer`.
