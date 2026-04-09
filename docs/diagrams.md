# Diagrams

**Status: Planned (Phase 4)**

S2DCartographer will generate SVG diagrams for embedding in reports, documentation, and presentations.

## Diagram Types

### Capacity Waterfall (`-DiagramType Waterfall`)

Horizontal bar chart showing each stage of capacity consumption from raw to usable, with values and stage labels:

```
Raw Capacity         ████████████████████████████████████  41.92 TiB
  − Pool overhead    ░                                     −0.21 TiB
  − Reserve          ████                                  −10.48 TiB
  − Infra volume     ░                                     −0.25 TiB
  = Available        ████████████████████                   30.98 TiB
  − Mirror overhead  ████████████████████                  −20.65 TiB
  = USABLE           ██████████                             10.33 TiB
```

### Disk-to-Node Map (`-DiagramType DiskNodeMap`)

One box per node containing all disks, color-coded by role (cache = blue, capacity = green) and health (amber/red for degraded).

### Storage Pool Layout (`-DiagramType PoolLayout`)

Stacked bar or pie showing pool allocation broken down by volume, reserve space, infrastructure volume, and free space.

### Volume Resiliency Map (`-DiagramType Resiliency`)

Per-volume diagram showing data copy distribution across fault domains (nodes), with efficiency percentage.

### Health Scorecard (`-DiagramType HealthCard`)

SVG dashboard with traffic-light indicators for each health check area.

### TiB/TB Reference Chart (`-DiagramType TiBTBReference`)

Visual conversion table showing common NVMe/SSD drive sizes in both units.

## Usage

```powershell
# Generate all diagrams
$data = Invoke-S2DCartographer -ClusterName "c01-prd-bal" -Credential $cred -PassThru
$data | New-S2DDiagram -DiagramType All -OutputPath "C:\Reports\diagrams\"

# Waterfall only
$data | New-S2DDiagram -DiagramType Waterfall -OutputPath "C:\Reports\waterfall.svg"
```

Diagrams are automatically embedded in Word and PDF reports when `-IncludeDiagrams` is specified on `Invoke-S2DCartographer`.
