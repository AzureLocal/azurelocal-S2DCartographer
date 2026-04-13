# Cluster Snapshot JSON Schema

The `.json` file written to every per-run folder by `Invoke-S2DCartographer` (and by `New-S2DReport -Format Json`) is a structured snapshot of the collected cluster data. The schema is a **stable API** — downstream tools can depend on the shape of this file.

- **File name**: `S2DCartographer_<ClusterName>_<yyyyMMdd-HHmm>.json`
- **Encoding**: UTF-8
- **Pretty-printed**: yes (for git-diff friendliness)
- **Canonical sample**: [`samples/cluster-snapshot.json`](https://github.com/AzureLocal/azurelocal-s2d-cartographer/blob/main/samples/cluster-snapshot.json)

## Versioning

The top-level `SchemaVersion` field is SemVer-ish:

- **Minor bumps** (e.g., `1.0` → `1.1`) — additive changes only (new optional fields)
- **Major bumps** (e.g., `1.x` → `2.0`) — rename, removal, or meaning change of an existing field

Downstream tools should read `SchemaVersion`, tolerate minor bumps, and fail fast on major bumps with a clear message.

Current version: **`1.0`**

## Top-level shape

```json
{
  "SchemaVersion": "1.0",
  "Generated": { ... },
  "Cluster": { ... },
  "OverallHealth": "Healthy | Warning | Critical | Fail | Unknown",
  "PhysicalDisks": [ ... ],
  "StoragePool": { ... },
  "Volumes": [ ... ],
  "CacheTier": { ... },
  "CapacityWaterfall": { ... },
  "HealthChecks": [ ... ]
}
```

### `Generated`

Metadata about the run that produced this snapshot.

| Field | Type | Description |
|---|---|---|
| `Timestamp` | string (ISO 8601 UTC) | When the JSON was written |
| `ModuleVersion` | string | S2DCartographer module version that produced the file |
| `Author` | string | Passed via `-Author` on the run (may be empty) |
| `Company` | string | Passed via `-Company` on the run (may be empty) |

### `Cluster`

Cluster metadata and node list.

| Field | Type | Description |
|---|---|---|
| `Name` | string | Cluster name as returned by the cluster itself |
| `Fqdn` | string | Resolved FQDN used for the CIM session |
| `NodeCount` | int | Number of cluster nodes |
| `Nodes` | array of string | Short node names |
| `CollectedAt` | string (ISO 8601 UTC) | When collection started |

### `OverallHealth`

Rolled-up health status computed from `HealthChecks[]`. One of:

- `Healthy` — every check passed
- `Warning` — at least one non-critical check failed
- `Critical` / `Fail` — at least one critical check failed
- `Unknown` — checks were skipped (`-SkipHealthChecks`)

### `PhysicalDisks[]`

One entry per physical disk visible to any cluster node. **Every disk is included**, including boot drives and SAN-presented LUNs — use `IsPoolMember` to filter if you only want S2D pool members.

| Field | Type | Description |
|---|---|---|
| `NodeName` | string | Node where the disk is enumerated |
| `DiskNumber` | int | Windows disk number |
| `UniqueId` | string | Disk unique ID |
| `FriendlyName` | string | Human-friendly disk name |
| `SerialNumber` | string | Manufacturer serial |
| `Model` | string | Model string |
| `MediaType` | string | `NVMe` / `SSD` / `HDD` / `Unspecified` |
| `BusType` | string | `NVMe` / `SAS` / `SATA` / `FC` / etc. |
| `FirmwareVersion` | string | Firmware string |
| `Manufacturer` | string | Vendor name |
| `Role` | string | `Cache` / `Capacity` / `Unknown` (Unknown means not a pool member) |
| `Usage` | string | Windows disk usage: `Auto-Select` / `Journal` / `ManualSelect` / `HotSpare` |
| `CanPool` | bool | Windows reports that this disk could be added to a pool |
| **`IsPoolMember`** | bool | **Whether the disk is a member of the S2D storage pool. Filter on this to exclude boot drives / SAN LUNs.** |
| `HealthStatus` | string | `Healthy` / `Warning` / `Unhealthy` / `Unknown` |
| `OperationalStatus` | string | Windows operational status |
| `PhysicalLocation` | string | Enclosure / slot description |
| `SlotNumber` | int | Physical slot number |
| `Size` | [`S2DCapacity`](#s2dcapacity) | Disk capacity |
| `SizeBytes` | int64 | Convenience — flat bytes |
| `Temperature` | int | Celsius (if reported) |
| `WearPercentage` | int | SSD wear % (NVMe / SSD only) |
| `PowerOnHours` | int | Cumulative power-on hours |
| `ReadErrors` / `WriteErrors` | int | Counters |
| `ReadLatency` / `WriteLatency` | int | Milliseconds |

### `StoragePool`

Properties of the single S2D storage pool.

| Field | Type | Description |
|---|---|---|
| `FriendlyName` | string | Pool name |
| `HealthStatus` | string | `Healthy` / `Warning` / `Unhealthy` |
| `OperationalStatus` | string | Windows operational status |
| `IsReadOnly` | bool | |
| `TotalSize` | [`S2DCapacity`](#s2dcapacity) | Full pool capacity |
| `AllocatedSize` | [`S2DCapacity`](#s2dcapacity) | Consumed by volumes |
| `RemainingSize` | [`S2DCapacity`](#s2dcapacity) | Free pool space |
| `ProvisionedSize` | [`S2DCapacity`](#s2dcapacity) | Logical sum of volume sizes (thin-provisioning visible here) |
| `OvercommitRatio` | double | `ProvisionedSize / TotalSize` |
| `FaultDomainAwareness` | string | `StorageScaleUnit` / `Rack` / etc. |
| `ResiliencySettings` | array | Per-setting resiliency definitions |
| `StorageTiers` | array | Pool tier definitions |

### `Volumes[]`

One entry per volume in the pool.

| Field | Type | Description |
|---|---|---|
| `FriendlyName` | string | Volume name |
| `FileSystem` | string | `ReFS` / `NTFS` / `CSVFS_ReFS` |
| `ResiliencySettingName` | string | `Mirror` / `Parity` / `Mirror-Accelerated Parity` |
| `NumberOfDataCopies` | int | 2 / 3 for two-way / three-way mirror |
| `PhysicalDiskRedundancy` | int | Failures the volume can survive |
| `ProvisioningType` | string | `Thin` / `Fixed` |
| `Size` | [`S2DCapacity`](#s2dcapacity) | Volume size presented to VMs |
| `FootprintOnPool` | [`S2DCapacity`](#s2dcapacity) | Actual pool consumption (size × resiliency multiplier) |
| `AllocatedSize` | [`S2DCapacity`](#s2dcapacity) | Data written |
| `EfficiencyPercent` | double | Size / FootprintOnPool × 100 |
| `OvercommitRatio` | double | For thin volumes |
| `IsInfrastructureVolume` | bool | Azure Local management-plane volume |
| `IsDeduplicationEnabled` | bool | |
| `HealthStatus` / `OperationalStatus` | string | |

### `CacheTier`

| Field | Type | Description |
|---|---|---|
| `CacheMode` | string | `ReadWrite` / `ReadOnly` / `Disabled` |
| `IsAllFlash` | bool | All-flash cluster detection |
| `SoftwareCacheEnabled` | bool | S2D software write-back cache enabled |
| `CacheDiskCount` | int | Number of cache drives across all nodes |
| `CacheDiskModel` | string | Cache drive model |
| `CacheDiskSize` | [`S2DCapacity`](#s2dcapacity) | Per-drive size |
| `CacheToCapacityRatio` | double | Ratio of cache bytes to capacity bytes |
| `CacheState` | string | `Active` / `Degraded` / `Disabled` |
| `WriteCacheSizeBytes` | int64 | Bytes per capacity drive reserved for cache |

### `CapacityWaterfall`

The 8-stage capacity accounting model.

| Field | Type | Description |
|---|---|---|
| `Stages` | array of `S2DWaterfallStage` | Ordered array, 8 entries |
| `RawCapacity` | [`S2DCapacity`](#s2dcapacity) | Stage 1 |
| `UsableCapacity` | [`S2DCapacity`](#s2dcapacity) | Stage 8 |
| `ReserveRecommended` | [`S2DCapacity`](#s2dcapacity) | Best-practice reserve |
| `ReserveActual` | [`S2DCapacity`](#s2dcapacity) | Actual free pool space |
| `ReserveStatus` | string | `Adequate` / `Warning` / `Critical` |
| `IsOvercommitted` | bool | Pool is overcommitted |
| `OvercommitRatio` | double | Overcommit ratio |
| `NodeCount` | int | Nodes used in the calculation |
| `BlendedEfficiencyPercent` | double | Weighted resiliency efficiency across volumes |

#### `Stages[]` entry (`S2DWaterfallStage`)

| Field | Type | Description |
|---|---|---|
| `Stage` | int | 1–8 |
| `Name` | string | Stage name |
| `Size` | [`S2DCapacity`](#s2dcapacity) | Remaining capacity at this stage |
| `Delta` | [`S2DCapacity`](#s2dcapacity) | Reduction from previous stage |
| `Description` | string | Human-readable description |
| `Status` | string | `OK` / `Warn` / `Fail` |

### `HealthChecks[]`

One entry per check (10 at time of writing).

| Field | Type | Description |
|---|---|---|
| `CheckName` | string | Stable identifier (e.g., `ReserveAdequacy`, `DiskSymmetry`, `NVMeWear`) |
| `Severity` | string | `Info` / `Warning` / `Critical` |
| `Status` | string | `Pass` / `Warn` / `Fail` |
| `Details` | string | Human-readable detail text |
| `Remediation` | string | Suggested fix |

## `S2DCapacity`

Every size field in the schema is an `S2DCapacity` object with both binary and decimal units. Downstream consumers never have to convert.

```json
{
  "Bytes":   3840000000000,
  "TiB":     3.49,
  "TB":      3.84,
  "GiB":     3576.28,
  "GB":      3840.0,
  "Display": "3.49 TiB (3.84 TB)"
}
```

## Consuming the snapshot

### PowerShell

```powershell
$snap = Get-Content ./S2DCartographer_*.json -Raw | ConvertFrom-Json
$snap.PhysicalDisks | Where-Object IsPoolMember | Measure-Object -Property SizeBytes -Sum
$snap.HealthChecks  | Where-Object Status -ne 'Pass'
```

### jq

```bash
jq '.PhysicalDisks | map(select(.IsPoolMember)) | length' snapshot.json
jq '.CapacityWaterfall.UsableCapacity.TiB' snapshot.json
jq '.HealthChecks[] | select(.Status != "Pass") | {CheckName, Status, Details}' snapshot.json
```

### Python

```python
import json
with open('snapshot.json') as f:
    snap = json.load(f)

pool_disks = [d for d in snap['PhysicalDisks'] if d.get('IsPoolMember')]
print(f"{len(pool_disks)} pool-member disks totaling {snap['CapacityWaterfall']['RawCapacity']['TB']} TB raw")
```

## Stability guarantees

- **Field names** — stable within a major SchemaVersion
- **Field types** — stable within a major SchemaVersion
- **Field presence** — required fields listed above are always present. Optional fields (e.g., OEM enrichment fields added by future features) will be documented separately and absent when not applicable.
- **Array ordering** — `CapacityWaterfall.Stages[]` is always ordered 1→8. Other arrays (disks, volumes, nodes, health checks) have no guaranteed order — sort by a stable field if ordering matters.

## Related

- [`reports.md`](../reports.md) — All supported output formats
- [`collectors/physical-disks.md`](../collectors/physical-disks.md) — `IsPoolMember` and what counts as a pool disk
- [`capacity-math.md`](../capacity-math.md) — How the waterfall stages are computed
