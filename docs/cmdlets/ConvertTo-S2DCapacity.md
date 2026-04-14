# ConvertTo-S2DCapacity

Converts a storage capacity value to a dual-unit S2DCapacity object.

---

## Synopsis

Takes a capacity expressed in bytes, TB (decimal), TiB (binary), GB (decimal), or GiB (binary) and returns an `S2DCapacity` object containing all unit representations plus a `Display` string showing both TiB and TB.

This is the canonical conversion utility used throughout S2DCartographer to eliminate TiB vs TB confusion. See [TiB vs TB](../tib-vs-tb.md) for background.

---

## Syntax

**From bytes:**

```powershell
ConvertTo-S2DCapacity [-Bytes] <int64>
```

**From decimal terabytes (drive label):**

```powershell
ConvertTo-S2DCapacity -TB <double>
```

**From binary tebibytes (Windows display):**

```powershell
ConvertTo-S2DCapacity -TiB <double>
```

**From decimal gigabytes:**

```powershell
ConvertTo-S2DCapacity -GB <double>
```

**From binary gibibytes:**

```powershell
ConvertTo-S2DCapacity -GiB <double>
```

---

## Parameters

### `-Bytes`

| | |
|---|---|
| Type | `int64` |
| Required | Yes (Bytes parameter set) |
| Position | 0 |
| Pipeline | Yes |
| Default | — |

Capacity in bytes. Pipeline-compatible — pipe raw byte values from WMI or CIM properties.

---

### `-TB`

| | |
|---|---|
| Type | `double` |
| Required | Yes (TB parameter set) |
| Default | — |

Capacity in decimal terabytes (drive manufacturer labeling). 1 TB = 1,000,000,000,000 bytes.

---

### `-TiB`

| | |
|---|---|
| Type | `double` |
| Required | Yes (TiB parameter set) |
| Default | — |

Capacity in binary tebibytes (Windows reporting). 1 TiB = 1,099,511,627,776 bytes.

---

### `-GB`

| | |
|---|---|
| Type | `double` |
| Required | Yes (GB parameter set) |
| Default | — |

Capacity in decimal gigabytes. 1 GB = 1,000,000,000 bytes.

---

### `-GiB`

| | |
|---|---|
| Type | `double` |
| Required | Yes (GiB parameter set) |
| Default | — |

Capacity in binary gibibytes. 1 GiB = 1,073,741,824 bytes.

---

## Outputs

`S2DCapacity` — an object with the following properties:

| Property | Type | Description |
|---|---|---|
| `Bytes` | `int64` | Raw byte value |
| `TiB` | `double` | Binary tebibytes |
| `TB` | `double` | Decimal terabytes |
| `GiB` | `double` | Binary gibibytes |
| `GB` | `double` | Decimal gigabytes |
| `Display` | `string` | Human-readable dual-unit string, e.g. `3.49 TiB (3.84 TB)` |

---

## Examples

**From raw bytes:**

```powershell
ConvertTo-S2DCapacity -Bytes 3840755982336
# Returns Display: 3.49 TiB (3.84 TB)
```

**From drive-label TB:**

```powershell
ConvertTo-S2DCapacity -TB 1.92
# Returns Display: 1.75 TiB (1.92 TB)
```

**From Windows-displayed TiB:**

```powershell
ConvertTo-S2DCapacity -TiB 13.97
# Returns Display: 13.97 TiB (15.36 TB)
```

**Pipeline from WMI disk size:**

```powershell
Get-PhysicalDisk | Select-Object -ExpandProperty Size | ConvertTo-S2DCapacity
```

**Use the display string:**

```powershell
$cap = ConvertTo-S2DCapacity -TB 3.84
"Drive size: $($cap.Display)"
# Drive size: 3.49 TiB (3.84 TB)
```
