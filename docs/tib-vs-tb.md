# TiB vs TB — Understanding the Difference

This is one of the most common sources of confusion when working with Storage Spaces Direct. S2DCartographer treats it as a first-class problem, not an afterthought.

## The Core Issue

Drive manufacturers label capacity in **terabytes (TB)** — the decimal system where 1 TB = 1,000,000,000,000 bytes.

Windows (and S2D) report capacity in **tebibytes (TiB)** — the binary system where 1 TiB = 1,099,511,627,776 bytes.

The result: a drive labeled "1.92 TB" by the manufacturer shows as **1.75 TiB** in Windows. The drive is not broken. The numbers are just in different units.

## The Conversion Table

| Drive Label (TB) | Actual Bytes | Windows Shows (TiB) | Gap |
|------------------|-------------|---------------------|-----|
| 960 GB | 960,000,000,000 | 0.87 TiB | −6.9% |
| 1.92 TB | 1,920,000,000,000 | 1.75 TiB | −6.9% |
| 3.84 TB | 3,840,000,000,000 | 3.49 TiB | −6.9% |
| 7.68 TB | 7,680,000,000,000 | 6.98 TiB | −6.9% |
| 15.36 TB | 15,360,000,000,000 | 13.97 TiB | −6.9% |

The gap is always approximately **6.9%** because 1 TiB / 1 TB = 1.0995, and the inverse gives a ~9.75% difference — which averages to the ~6.9% capacity gap you actually see.

## How S2DCartographer Handles It

Every capacity value in every output is displayed in **dual format**:

```
Raw Capacity:  13.97 TiB  (15.36 TB)
Usable Space:   4.66 TiB  ( 5.12 TB)
```

This is enforced throughout the entire tool using the `S2DCapacity` class:

```powershell
class S2DCapacity {
    [int64]  $Bytes    # Authoritative source of truth
    [double] $TiB      # Binary: bytes ÷ 1,099,511,627,776
    [double] $TB       # Decimal: bytes ÷ 1,000,000,000,000
    [double] $GiB      # Binary: bytes ÷ 1,073,741,824
    [double] $GB       # Decimal: bytes ÷ 1,000,000,000
    [string] $Display  # "13.97 TiB (15.36 TB)"
}
```

## The ConvertTo-S2DCapacity Utility

You can use `ConvertTo-S2DCapacity` directly in your own scripts:

```powershell
# From bytes (what Windows CIM returns)
ConvertTo-S2DCapacity -Bytes 1920000000000
# Returns: 1.75 TiB (1.92 TB)

# From a drive label (what the manufacturer says)
ConvertTo-S2DCapacity -TB 3.84
# Returns: 3.49 TiB (3.84 TB)

# From what Windows reports
ConvertTo-S2DCapacity -TiB 13.97
# Returns: 13.97 TiB (15.36 TB)
```

## Why This Matters for Capacity Planning

A 4-node cluster with 4× 3.84 TB NVMe per node:

- **Marketing math**: 4 nodes × 4 drives × 3.84 TB = **61.44 TB** raw
- **Windows reality**: 4 × 4 × 3.49 TiB = **55.88 TiB** raw

Before even accounting for resiliency or reserve space, you've already "lost" ~5.5 TiB just to unit conversion. This is why customers are surprised when their storage capacity is less than they expected.

S2DCartographer makes this gap visible at every stage of the capacity waterfall.
