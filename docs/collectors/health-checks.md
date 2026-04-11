# Get-S2DHealthStatus

Runs all 10 S2D health checks and returns pass/warn/fail results with severity levels and remediation guidance.

---

## Syntax

```powershell
Get-S2DHealthStatus [[-CheckName] <string[]>]
```

## Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `-CheckName` | `string[]` | Limit results to one or more specific check names. |

---

## Prerequisites

`Get-S2DHealthStatus` depends on all four primary collectors. It runs them automatically if their data is not already cached:

- `Get-S2DPhysicalDiskInventory` — disk health, symmetry, wear, firmware
- `Get-S2DStoragePoolInfo` — pool free space, overcommit ratio
- `Get-S2DVolumeMap` — volume health, infrastructure volume
- `Get-S2DCacheTierInfo` — cache state
- `Get-S2DCapacityWaterfall` — reserve status

---

## Output

Returns `S2DHealthCheck[]` — one object per health check.

| Property | Type | Description |
| --- | --- | --- |
| `CheckName` | `string` | Check identifier |
| `Severity` | `string` | `Critical`, `Warning`, or `Info` |
| `Status` | `string` | `Pass`, `Warn`, or `Fail` |
| `Details` | `string` | What was found — values from live cluster data |
| `Remediation` | `string` | What to do when Status is not Pass |

### Overall health rollup

After each run, `Get-S2DHealthStatus` writes an overall health string to `$Script:S2DSession.CollectedData['OverallHealth']`:

| Overall | Condition |
| --- | --- |
| `Critical` | Any Critical-severity check has `Status = Fail` |
| `Warning` | No Critical failures, but at least one check has `Status = Warn` or `Fail` |
| `Healthy` | All checks passed |

---

## The 10 Health Checks

### 1 — ReserveAdequacy

**Severity:** Critical

Compares actual pool free space against the S2D-recommended rebuild reserve.

| Status | Condition |
| --- | --- |
| Pass | `ReserveActual ≥ ReserveRecommended` |
| Warn | `ReserveActual ≥ 50% of ReserveRecommended` |
| Fail | `ReserveActual < 50% of ReserveRecommended` |

**Reserve formula:** `min(NodeCount, 4) × LargestCapacityDriveSize`

**Remediation (Warn/Fail):** Free pool space by deleting or shrinking volumes, or add capacity drives to the pool.

!!! danger "Why this is Critical"
    If the reserve is insufficient and a drive fails, the storage pool cannot complete a full rebuild. A second failure during an in-progress rebuild risks data loss.

---

### 2 — DiskSymmetry

**Severity:** Warning

Checks that all cluster nodes have the same number of physical disks.

| Status | Condition |
| --- | --- |
| Pass | All nodes report the same disk count |
| Warn | Disk count differs across one or more nodes |

**Remediation:** Investigate missing or additional disks. S2D requires symmetric disk configurations for balanced performance and correct reserve calculations.

---

### 3 — VolumeHealth

**Severity:** Critical

Checks that all virtual disks are in a healthy operational state.

| Status | Condition |
| --- | --- |
| Pass | All volumes have `HealthStatus = Healthy` and `OperationalStatus` in `{OK, InService, Online}` |
| Fail | One or more volumes are degraded, detached, or in error |

**Remediation:** Run `Get-VirtualDisk` and check cluster event logs for storage health reports.

---

### 4 — DiskHealth

**Severity:** Critical

Checks that all physical disks are in `Healthy` state.

| Status | Condition |
| --- | --- |
| Pass | All physical disks report `HealthStatus = Healthy` |
| Fail | One or more disks are Warning or Unhealthy |

**Remediation:** Replace failed or degraded disks promptly. Check `Get-PhysicalDisk -HasMediaFailure`.

---

### 5 — NVMeWear

**Severity:** Warning

Checks that no NVMe drive exceeds 80% wear percentage.

| Status | Condition |
| --- | --- |
| Pass | No NVMe drive has `WearPercentage > 80` |
| Warn | One or more NVMe drives exceed the 80% threshold |

**Remediation:** Plan replacement for high-wear NVMe drives before they reach 100% (end of rated write endurance). Use `Get-S2DPhysicalDiskInventory` to monitor ongoing wear.

!!! note "Wear data availability"
    `WearPercentage` comes from `Get-StorageReliabilityCounter`. Some drivers do not expose this counter — if `WearPercentage` is `$null` for all drives, the check passes (no evidence of excess wear). Use `-Verbose` to see which disks have null reliability data.

---

### 6 — ThinOvercommit

**Severity:** Warning

Checks whether the total logical size of all thin-provisioned volumes exceeds pool capacity.

| Status | Condition |
| --- | --- |
| Pass | `OvercommitRatio ≤ 1.0` |
| Warn | `OvercommitRatio > 1.0` |

**Remediation:** Monitor actual data growth. Add capacity drives or reduce provisioned volume sizes before the pool runs out of physical space.

---

### 7 — FirmwareConsistency

**Severity:** Info

Checks that all disks of the same model are running the same firmware version.

| Status | Condition |
| --- | --- |
| Pass | No model has more than one firmware version across all nodes |
| Warn | At least one model has mixed firmware versions |

**Remediation:** Update all drives of the same model to the latest firmware using the vendor update tool or Dell/HPE/Lenovo HCI management utilities.

---

### 8 — RebuildCapacity

**Severity:** Critical

Checks whether free pool space is sufficient to absorb the loss of the largest single node's disk capacity.

| Status | Condition |
| --- | --- |
| Pass | `PoolFreeSpace ≥ LargestNodeDiskCapacity` |
| Warn | `PoolFreeSpace < LargestNodeDiskCapacity` |

**Remediation:** Free pool space by removing or shrinking volumes. Consider adding capacity drives.

!!! note "Relationship to ReserveAdequacy"
    `ReserveAdequacy` checks against the recommended reserve formula `(min(NodeCount,4) × largest drive)`. `RebuildCapacity` checks against the practical rebuild requirement `(largest node's total disk capacity)`. Both can fail independently.

---

### 9 — InfrastructureVolume

**Severity:** Info

Verifies that the Azure Local infrastructure volume is present and healthy.

| Status | Condition |
| --- | --- |
| Pass | One or more infrastructure volumes detected and all are `Healthy` |
| Warn | Infrastructure volume present but not fully healthy, or no infrastructure volume detected |

**Remediation:** On Azure Local, the infrastructure volume hosts cluster metadata and CSV cache. If missing or degraded, investigate with `Get-VirtualDisk`. A missing infrastructure volume may indicate a deployment issue.

!!! note "Windows Server S2D"
    On Windows Server S2D (not Azure Local), an infrastructure volume is not always present. A `Warn` status for this check on Windows Server may be expected — use context to determine if action is needed.

---

### 10 — CacheTierHealth

**Severity:** Warning

Checks cache tier health across both physical and software cache configurations.

| Status | Condition |
| --- | --- |
| Pass (all-flash) | `IsAllFlash = $true` and `SoftwareCacheEnabled = $true` |
| Pass (hybrid) | `CacheState = Active` |
| Warn | `CacheState = Degraded`, or cache tier data unavailable |

**Remediation (Degraded):** Check cache disk health with `Get-S2DPhysicalDiskInventory`. Replace failed cache drives promptly — a degraded cache tier significantly reduces write performance.

---

## Examples

```powershell
# All checks
Get-S2DHealthStatus | Format-Table CheckName, Severity, Status, Details

# Non-passing checks only
Get-S2DHealthStatus | Where-Object Status -ne 'Pass' | Format-List

# Specific checks
Get-S2DHealthStatus -CheckName 'ReserveAdequacy', 'NVMeWear', 'DiskHealth'

# Overall health rollup
Get-S2DHealthStatus | Out-Null
$Script:S2DSession  # read directly; or use Invoke-S2DCartographer -PassThru

# Remediation report
Get-S2DHealthStatus |
    Where-Object Status -ne 'Pass' |
    Select-Object CheckName, Severity, Status, Remediation |
    Format-List
```

---

## Troubleshooting

!!! warning "Check results reflect cached data"
    `Get-S2DHealthStatus` uses cached collector data when available. If you suspect stale results, clear the cache by disconnecting and reconnecting:

    ```powershell
    Disconnect-S2DCluster
    Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential $cred
    Get-S2DHealthStatus
    ```

!!! tip "Running specific checks for monitoring"
    Use `-CheckName` for lightweight monitoring scripts that only need to evaluate a subset of checks. This does not skip prerequisite data collection — all collectors are still run if their data is not cached.

    ```powershell
    # Fast reserve-only check
    Get-S2DPhysicalDiskInventory | Out-Null
    Get-S2DStoragePoolInfo       | Out-Null
    Get-S2DCapacityWaterfall     | Out-Null
    Get-S2DHealthStatus -CheckName 'ReserveAdequacy'
    ```
