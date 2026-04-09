function Get-S2DCapacityWaterfall {
    <#
    .SYNOPSIS
        Computes the 8-stage capacity waterfall from raw physical to final usable capacity.

    .DESCRIPTION
        Phase 2 — Not yet implemented.

        Will compute:
          Stage 1: Raw physical capacity (capacity-tier disks only)
          Stage 2: After vendor TB labeling → TiB adjustment
          Stage 3: After storage pool overhead (~0.5-1%)
          Stage 4: After reserve space (min(NodeCount,4) × largest capacity drive)
          Stage 5: After infrastructure volume
          Stage 6: Available for workload volumes
          Stage 7: After resiliency overhead (per volume, mixed resiliency supported)
          Stage 8: Final usable capacity

        Also reports expected vs actual for reserve space and overcommit status.
    #>
    [CmdletBinding()]
    param()

    throw "Get-S2DCapacityWaterfall is not implemented yet. This is a Phase 2 deliverable. See the project plan for the roadmap."
}
