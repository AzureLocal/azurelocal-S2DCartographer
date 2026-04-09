# Capacity Math — The 8-Stage Waterfall

S2DCartographer computes a full capacity waterfall that shows how storage capacity is consumed at every stage from raw physical disks to final usable VM space.

## The 8 Stages

### Stage 1 — Raw Physical Capacity

Sum of all **capacity-tier** disk sizes across all nodes. Cache-tier disks are excluded — they don't contribute to pool capacity.

```
Example: 3-node cluster, 4× 3.84 TB SSD per node
Raw = 3 nodes × 4 disks × 3.49 TiB = 41.92 TiB (45.96 TB labeled)
```

### Stage 2 — After Vendor Labeling Adjustment

Shows the discrepancy between drive labels (TB) and what Windows reports (TiB). This is the unit-conversion gap described in [TiB vs TB](tib-vs-tb.md). No actual bytes are lost here — this stage makes the confusion visible.

### Stage 3 — After Storage Pool Overhead

The pool consumes a small amount of space for metadata. Approximately 0.5–1% of raw capacity.

### Stage 4 — After Reserve Space

Microsoft recommends keeping `min(NodeCount, 4)` capacity drive equivalents **unallocated** in the pool. This reserve allows the pool to rebuild after a drive failure.

```
Formula: Reserve = min(NodeCount, 4) × LargestCapacityDriveSize

3-node cluster, 3.84 TB drives:
Reserve = min(3,4) × 3.49 TiB = 10.48 TiB
```

S2DCartographer reports the recommended reserve, the actual unallocated space, and whether the reserve is adequate.

### Stage 5 — After Infrastructure Volume

Azure Local automatically creates an infrastructure volume for cluster metadata, storage bus logs, and CSV metadata. This typically consumes 250–500 GiB depending on cluster size.

S2DCartographer detects the infrastructure volume by name and size pattern and breaks it out separately so you can account for it.

### Stage 6 — Available for Workload Volumes

What remains after reserve and infrastructure volume. This is the budget from which all user-created volumes draw their pool footprint.

### Stage 7 — After Resiliency Overhead

Each volume's logical size is a fraction of its pool footprint based on the resiliency type:

| Resiliency Type | Efficiency | Footprint Formula |
|-----------------|-----------|-------------------|
| Three-way mirror | 33.3% | Usable × 3 |
| Two-way mirror | 50% | Usable × 2 |
| Nested two-way mirror (2-node) | 25% | Usable × 4 |
| Dual parity (4-node) | 50% | Varies by node count |
| Dual parity (6-node) | 66.7% | Varies by node count |

When volumes use different resiliency types, S2DCartographer computes overhead per volume and reports a blended efficiency for the cluster overall.

### Stage 8 — Final Usable Capacity

The sum of all volume logical sizes. This is what VMs and workloads can actually consume.

## Expected vs Actual

For each stage, S2DCartographer shows:

| Stage | Expected (Best Practice) | Actual (This Cluster) | Status |
|-------|--------------------------|----------------------|--------|
| Reserve space | 10.48 TiB | 2.1 TiB | ⚠️ INSUFFICIENT |
| Infrastructure volume | Present | Present (256 GiB) | ✅ OK |
| Volumes provisioned | ≤ available | 105% overcommit | 🔴 CRITICAL |

## Thin Overcommit Detection

Thin-provisioned volumes have a logical size greater than the current pool footprint. S2DCartographer flags clusters where the total logical size of all thin volumes exceeds the remaining available capacity — a dangerous condition that can cause unexpected out-of-space failures.
