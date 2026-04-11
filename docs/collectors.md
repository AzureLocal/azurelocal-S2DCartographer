# Collectors

S2DCartographer collects data from your cluster using standard PowerShell storage and cluster cmdlets over CIM/WinRM. No agents are installed on cluster nodes. All collection is **read-only**.

Data is cached in the module session after first collection. Subsequent calls to `Get-S2DCapacityWaterfall` or `Get-S2DHealthStatus` reuse cached results automatically — no redundant queries.

---

## Physical Disk Inventory — `Get-S2DPhysicalDiskInventory`

Queries each cluster node for all physical disks in the S2D pool plus pool membership.

**Returns:** `S2DPhysicalDisk[]`

**Collects:**

- Media type (NVMe, SSD, HDD), bus type, model, firmware version, manufacturer
- Disk number and physical location (enriched from `Get-Disk`)
- Capacity in TiB and TB
- Usage classification (Auto-Select, Journal, Retired) and role (Cache or Capacity tier)
- Health and operational status
- Reliability counters: temperature, NVMe wear %, power-on hours, read/write errors, read/write latency

**Anomaly detection** — warns on first collection if:

- Disk counts are inconsistent across nodes (asymmetric configuration)
- Capacity sizes are mixed within the same media type
- Firmware versions differ across disks of the same model
- Any disks are in non-Healthy state

**CIM sources:**

```powershell
Get-PhysicalDisk
Get-PhysicalDisk | Get-StorageReliabilityCounter
Get-Disk
Get-StoragePool | Get-PhysicalDisk
```

**Example:**

```powershell
Get-S2DPhysicalDiskInventory | Format-Table NodeName, FriendlyName, Role, Size, WearPercentage, HealthStatus
```

---

## Storage Pool — `Get-S2DStoragePoolInfo`

Queries the non-primordial S2D storage pool for health, capacity, resiliency configuration, and storage tiers.

**Returns:** `S2DStoragePool`

**Collects:**

- Pool friendly name, health status, operational status, read-only flag
- Total, allocated, and remaining capacity as `S2DCapacity` (TiB + TB dual-display)
- Provisioned size (sum of all virtual disk logical sizes) for overcommit detection
- Overcommit ratio — provisioned ÷ pool total
- Resiliency settings available in the pool (Mirror, Parity, and their configurations)
- Storage tiers (Performance/Capacity tier sizes)
- Fault domain awareness level (PhysicalDisk, StorageEnclosure, StorageScaleUnit)
- Write cache size default

**Parameters:**

| Parameter | Type | Description |
| ----------- | ------ | ------------- |
| `-CimSession` | `CimSession` | Override the module session CimSession |

**Example:**

```powershell
$pool = Get-S2DStoragePoolInfo
$pool | Select-Object FriendlyName, HealthStatus, TotalSize, RemainingSize, OvercommitRatio
```

---

## Volume Map — `Get-S2DVolumeMap`

Maps all virtual disks (S2D volumes) with resiliency type, capacity footprint, provisioning detail, and infrastructure volume classification.

**Returns:** `S2DVolume[]`

**Collects per volume:**

- Friendly name, file system (CSVFS_ReFS, CSVFS_NTFS)
- Resiliency type (Mirror, Parity), number of data copies, physical disk redundancy
- Provisioning type (Fixed, Thin)
- Logical size, pool footprint, and allocated size — all as `S2DCapacity`
- Health and operational status
- Deduplication enabled flag
- Infrastructure volume detection (by name pattern and size heuristic)
- Per-volume resiliency efficiency %

**Infrastructure volume detection:**

S2DCartographer detects the Azure Local infrastructure volume by name pattern (`Infrastructure_<guid>`, `ClusterPerformanceHistory`) and a size heuristic (< 600 GiB). These are broken out separately in the capacity waterfall so they don't inflate the workload capacity figure.

**Parameters:**

| Parameter | Type | Description |
| ----------- | ------ | ------------- |
| `-VolumeName` | `string[]` | Limit results to specific volume names |
| `-CimSession` | `CimSession` | Override the module session CimSession |

**Example:**

```powershell
Get-S2DVolumeMap | Format-Table FriendlyName, ResiliencySettingName, Size, FootprintOnPool, EfficiencyPercent, IsInfrastructureVolume
```

---

## Cache Tier — `Get-S2DCacheTierInfo`

Identifies the cache tier configuration — including all-flash clusters where S2D uses software write-back cache across all drives rather than a physical cache/capacity split.

**Returns:** `S2DCacheTier`

**Collects:**

- Cache mode (ReadWrite, ReadOnly, WriteOnly)
- All-flash cluster detection — `IsAllFlash = $true` when no HDD/Unknown media types are present
- Software cache enabled — `SoftwareCacheEnabled = $true` on all-flash clusters with no dedicated Journal disks
- Cache disk count, model, and size
- Cache-to-capacity drive ratio
- Cache state (Active, Degraded, Unknown)
- Write cache size in bytes

**All-NVMe / All-Flash clusters:** S2D does not use a physical cache tier on all-NVMe clusters. Instead it enables a software write-back cache across all drives. `Get-S2DCacheTierInfo` detects this automatically and sets `IsAllFlash = $true` and `SoftwareCacheEnabled = $true`.

**Example:**

```powershell
$cache = Get-S2DCacheTierInfo
$cache | Select-Object IsAllFlash, SoftwareCacheEnabled, CacheMode, CacheDiskCount, CacheState
```

---

## Health Status — `Get-S2DHealthStatus`

Runs all 10 health checks and returns pass/warn/fail results with severity and remediation guidance.

**Returns:** `S2DHealthCheck[]`

Uses already-collected data from the session cache where available. If prerequisite data is missing, the relevant collectors are called automatically.

**The 10 health checks:**

| Check Name | Severity | What it evaluates |
| ------------ | ---------- | -------------------- |
| `ReserveAdequacy` | Critical | Pool free space vs min(NodeCount,4) × largest drive |
| `DiskSymmetry` | Warning | Equal disk count across all nodes |
| `VolumeHealth` | Critical | All volumes in Healthy/OK state |
| `DiskHealth` | Critical | All physical disks in Healthy state |
| `NVMeWear` | Warning | NVMe wear percentage ≤ 80% |
| `ThinOvercommit` | Warning | Provisioned volume size vs pool total |
| `FirmwareConsistency` | Info | All disks of the same model on the same firmware |
| `RebuildCapacity` | Critical | Free pool space ≥ largest node's disk capacity |
| `InfrastructureVolume` | Info | Azure Local infrastructure volume present and healthy |
| `CacheTierHealth` | Warning | Cache tier active; software cache OK on all-flash |

**Overall health rollup** is written to `$Script:S2DSession.CollectedData['OverallHealth']` after each run:

- `Critical` — any Critical-severity check failed
- `Warning` — no Critical failures but at least one Warning/Info non-pass
- `Healthy` — all checks passed

**Parameters:**

| Parameter | Type | Description |
| ----------- | ------ | ------------- |
| `-CheckName` | `string[]` | Limit results to specific check names |

**Example:**

```powershell
# All checks
Get-S2DHealthStatus | Format-Table CheckName, Severity, Status, Details

# Only failing checks
Get-S2DHealthStatus | Where-Object Status -ne 'Pass' | Format-List

# Specific checks
Get-S2DHealthStatus -CheckName 'ReserveAdequacy', 'NVMeWear'
```

---

## Capacity Waterfall — `Get-S2DCapacityWaterfall`

Computes the 8-stage capacity accounting pipeline from raw physical capacity to final usable VM space.

**Returns:** `S2DCapacityWaterfall`

Uses already-collected data from the session cache — runs `Get-S2DPhysicalDiskInventory`, `Get-S2DStoragePoolInfo`, and `Get-S2DVolumeMap` automatically if their results are not already cached.

**The 8 stages:**

| Stage | Name | What changes |
| ------- | ------ | -------------- |
| 1 | Raw Physical | Sum of all capacity-tier disk bytes |
| 2 | Vendor Label (TB) | Display-only: shows the vendor decimal TB label vs Windows binary TiB |
| 3 | After Pool Overhead | Actual pool.TotalSize — captures ~0.5–1% pool metadata overhead |
| 4 | After Reserve | Subtracts min(NodeCount,4) × largest capacity drive |
| 5 | After Infra Volume | Subtracts the Azure Local infrastructure volume footprint |
| 6 | Available | Pool space available for workload volumes |
| 7 | After Resiliency | Subtracts total workload volume footprints (mirror/parity overhead) |
| 8 | Final Usable | Sum of workload volume logical sizes — what VMs can actually use |

**Reserve status** on Stage 4:

- `Adequate` — free space ≥ recommended reserve
- `Warning` — free space is 50–100% of recommended
- `Critical` — free space < 50% of recommended

**Example:**

```powershell
$wf = Get-S2DCapacityWaterfall

# Print the full pipeline
$wf.Stages | Format-Table Stage, Name, Size, Delta, Status

# Check reserve
"Reserve status: $($wf.ReserveStatus)"
"Recommended:    $($wf.ReserveRecommended.Display)"
"Actual free:    $($wf.ReserveActual.Display)"

# Final usable
"Usable capacity: $($wf.UsableCapacity.Display)"
```

See [Capacity Math](capacity-math.md) for a full explanation of each stage.
