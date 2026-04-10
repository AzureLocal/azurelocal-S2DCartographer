# Collectors

S2DCartographer collects data from your cluster using standard PowerShell storage and cluster cmdlets over CIM/WinRM. No agents are installed. All collection is read-only.

## Physical Disk Inventory (`Get-S2DPhysicalDiskInventory`)

**Status: Available (Phase 1)**

Queries each cluster node for all physical disks including:

- Media type (NVMe, SSD, HDD), bus type, model, firmware version
- Disk number and physical location enrichment from `Get-Disk`
- Per-disk capacity as both TiB and TB
- Usage classification (Auto-Select, Journal, Retired)
- Role classification (Cache or Capacity tier)
- Health and operational status
- Reliability counters: temperature, NVMe wear %, power-on hours, read/write errors, read/write latency when available
- Anomaly detection for disk symmetry, mixed capacity sizes, firmware inconsistencies, and non-healthy disks

**CIM sources used:**

```powershell
Get-PhysicalDisk
Get-PhysicalDisk | Get-StorageReliabilityCounter
Get-Disk
```

---

## Storage Pool Analysis (`Get-S2DStoragePoolInfo`)

**Status: Planned (Phase 2)**

Will collect:

- Pool health, operational status, read-only flag
- Total, allocated, and free capacity
- Provisioned size vs allocated size (thin overcommit detection)
- Storage tiers (Performance, Capacity)
- Resiliency settings available
- Fault domain awareness level

---

## Volume Map (`Get-S2DVolumeMap`)

**Status: Planned (Phase 2)**

Will collect per volume:

- Friendly name, file system
- Resiliency type and data copy count
- Provisioning type (Fixed or Thin)
- Logical size, pool footprint, and allocated size
- Health and operational status
- Deduplication status
- Infrastructure volume detection

---

## Cache Tier Analysis (`Get-S2DCacheTierInfo`)

**Status: Planned (Phase 2)**

Will collect:

- Cache mode (Read+Write, ReadOnly, WriteOnly)
- Cache disks per node (count, model, size, health)
- Cache-to-capacity binding ratio
- Degraded or missing cache drive detection

---

## Health Status (`Get-S2DHealthStatus`)

**Status: Planned (Phase 2)**

Will run all health checks and return pass/fail with severity (Critical/Warning/Info):

| Check | Severity |
|-------|----------|
| Reserve adequacy | Critical |
| Disk symmetry | Warning |
| Volume health | Critical |
| Disk health | Critical |
| NVMe wear >80% | Warning |
| Thin overcommit | Warning |
| Firmware consistency | Info |
| Rebuild capacity | Critical |
| Infrastructure volume | Info |
| Cache tier health | Warning |

---

## Capacity Waterfall (`Get-S2DCapacityWaterfall`)

**Status: Planned (Phase 2)**

Will compute all 8 stages of the capacity waterfall with an expected vs actual comparison at each stage. See [Capacity Math](capacity-math.md) for the full details.
