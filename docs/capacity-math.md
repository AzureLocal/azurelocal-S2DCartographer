# Capacity Math — The 8-Stage Waterfall

S2DCartographer computes a full capacity waterfall that shows how storage capacity is consumed at every stage from raw physical disks to final usable VM space.

---

## The 8 Stages

```mermaid
flowchart LR
    S1["**Stage 1**\nRaw Physical\n(capacity disks)"]
    S2["**Stage 2**\nVendor Label\n(TB display)"]
    S3["**Stage 3**\nPool Overhead\n(~1%)"]
    S4["**Stage 4**\nReserve\n(min(N,4)×drive)"]
    S5["**Stage 5**\nInfra Volume\n(250–500 GiB)"]
    S6["**Stage 6**\nAvailable\n(workload budget)"]
    S7["**Stage 7**\nResiliency\n(mirror/parity)"]
    S8["**Stage 8**\nFinal Usable\n(VM space)"]

    S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8
```

---

### Stage 1 — Raw Physical Capacity

Sum of all **capacity-tier** disk sizes across all nodes. Cache-tier disks are excluded — they don't contribute to pool capacity.

!!! example "3-node, all-NVMe cluster"
    ```text
    4 nodes × 4× Samsung PM9A3 3.84 TB NVMe = 16 drives × 3.49 TiB = 55.88 TiB
    ```

---

### Stage 2 — After Vendor Labeling Adjustment

Shows the discrepancy between drive labels (TB) and what Windows reports (TiB). This is the unit-conversion gap described in [TiB vs TB](tib-vs-tb.md). No actual bytes are lost — this stage makes the difference visible.

!!! info "No bytes change at Stage 2"
    Stage 2 is informational. The `Size` value does not change from Stage 1. The stage description shows the vendor-labeled TB value so you can compare it to your drive specification sheets.

---

### Stage 3 — After Storage Pool Overhead

The pool consumes a small amount of space for metadata. Approximately 0.5–1% of raw capacity. The actual value comes directly from `StoragePool.TotalSize` via CIM.

---

### Stage 4 — After Reserve Space

Microsoft recommends keeping `min(NodeCount, 4)` capacity drive equivalents **unallocated** in the pool. This reserve allows the pool to rebuild after a drive failure without exhausting available space.

```text
Reserve = min(NodeCount, 4) × LargestCapacityDriveSize
```

!!! example "Reserve calculation"
    ```text
    4-node cluster, 3.84 TB drives (3.49 TiB each):
    Reserve = min(4, 4) × 3.49 TiB = 13.97 TiB
    ```

S2DCartographer reports the recommended reserve, the actual unallocated space, and one of three statuses:

| Status | Condition |
| --- | --- |
| `Adequate` | Free space ≥ recommended reserve |
| `Warning` | Free space is 50–100% of recommended |
| `Critical` | Free space < 50% of recommended |

!!! danger "Critical reserve"
    A Critical reserve means the cluster cannot sustain a drive failure and complete a full rebuild. Free pool space immediately.

---

### Stage 5 — After Infrastructure Volume

Azure Local automatically creates an infrastructure volume for cluster metadata, storage bus logs, and CSV metadata. This typically consumes 250–500 GiB depending on cluster size.

S2DCartographer detects the infrastructure volume by name pattern and size heuristic, and breaks it out separately so it does not inflate the workload capacity figure.

!!! note "Detection patterns"
    Volumes are classified as infrastructure if they match `Infrastructure_<guid>`, `ClusterPerformanceHistory`, contain `infra` in the name, or are smaller than 600 GiB.

---

### Stage 6 — Available for Workload Volumes

What remains after reserve and infrastructure volume. This is the budget from which all user-created volumes draw their pool footprint.

---

### Stage 7 — After Resiliency Overhead

Each volume's logical size is a fraction of its pool footprint based on the resiliency type:

| Resiliency type | Efficiency | Pool footprint |
| --- | --- | --- |
| Three-way mirror | 33.3% | Usable × 3 |
| Two-way mirror | 50.0% | Usable × 2 |
| Nested two-way mirror (2-node) | 25.0% | Usable × 4 |
| Single parity (4-node) | 66.7% | Varies |
| Dual parity / LRC (6-node) | 66.7%+ | Varies |

When volumes use different resiliency types, S2DCartographer computes overhead per volume and reports a **blended efficiency** for the cluster overall.

---

### Stage 8 — Final Usable Capacity

The sum of all workload volume logical sizes. This is what VMs and workloads can actually consume.

---

## Example Waterfall

4-node cluster, 16× 3.84 TB NVMe (all capacity, all-NVMe):

| Stage | Name | Size | Delta |
| --- | --- | --- | --- |
| 1 | Raw Physical | 55.88 TiB | — |
| 2 | Vendor Label (TB) | 55.88 TiB | — (61.44 TB labeled) |
| 3 | Pool (after overhead) | 55.25 TiB | −0.63 TiB |
| 4 | After Reserve | 41.28 TiB | −13.97 TiB ⚠️ Warning |
| 5 | After Infra Volume | 40.97 TiB | −0.31 TiB |
| 6 | Available | 40.97 TiB | — |
| 7 | After Resiliency | 0.00 TiB | −40.97 TiB |
| 8 | **Final Usable** | **13.97 TiB** | — |

---

## Thin Overcommit Detection

Thin-provisioned volumes have a logical size greater than the current pool footprint. S2DCartographer flags clusters where the total logical size of all thin volumes exceeds the remaining available capacity — a dangerous condition that can cause unexpected out-of-space failures.

The `OvercommitRatio` from `Get-S2DStoragePoolInfo` and the `ThinOvercommit` health check in `Get-S2DHealthStatus` both surface this condition.

See [`Get-S2DCapacityWaterfall`](collectors/capacity-waterfall.md) for the full waterfall API reference.
