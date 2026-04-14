# Cmdlet Reference

Complete parameter reference for all public S2DCartographer cmdlets.

---

## Orchestration

| Cmdlet | Purpose |
|---|---|
| [Invoke-S2DCartographer](Invoke-S2DCartographer.md) | Full pipeline — connect, collect, analyze, and generate all reports in one call |
| [Invoke-S2DCapacityWhatIf](Invoke-S2DCapacityWhatIf.md) | Model capacity impact of hardware changes without touching the live cluster |

## Connection

| Cmdlet | Purpose |
|---|---|
| [Connect-S2DCluster](Connect-S2DCluster.md) | Establish an authenticated session to the cluster |
| [Disconnect-S2DCluster](Disconnect-S2DCluster.md) | Release the active session |

## Collectors

| Cmdlet | Purpose |
|---|---|
| [Get-S2DPhysicalDiskInventory](Get-S2DPhysicalDiskInventory.md) | Inventory all physical disks with health, capacity, and wear data |
| [Get-S2DStoragePoolInfo](Get-S2DStoragePoolInfo.md) | Storage pool configuration, capacity allocation, and overcommit status |
| [Get-S2DVolumeMap](Get-S2DVolumeMap.md) | Volume resiliency type, footprint, and provisioning detail |
| [Get-S2DCacheTierInfo](Get-S2DCacheTierInfo.md) | Cache tier configuration, binding ratio, and health |
| [Get-S2DCapacityWaterfall](Get-S2DCapacityWaterfall.md) | 7-stage theoretical capacity waterfall |
| [Get-S2DHealthStatus](Get-S2DHealthStatus.md) | All 11 health checks with pass/warn/fail results |

## Output

| Cmdlet | Purpose |
|---|---|
| [New-S2DReport](New-S2DReport.md) | Generate HTML, Word, PDF, Excel, JSON, or CSV reports |
| [New-S2DDiagram](New-S2DDiagram.md) | Generate SVG diagrams |

## Utilities

| Cmdlet | Purpose |
|---|---|
| [ConvertTo-S2DCapacity](ConvertTo-S2DCapacity.md) | Convert a capacity value to a dual-unit TiB/TB object |
