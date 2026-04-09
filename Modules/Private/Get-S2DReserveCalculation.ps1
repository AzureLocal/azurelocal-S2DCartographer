# Get-S2DReserveCalculation — computes the recommended and available reserve space.
# Used by Get-S2DCapacityWaterfall and Get-S2DHealthStatus.
#
# Microsoft recommendation: reserve the equivalent of 1 capacity drive per node,
# up to a maximum of 4 drives total, unallocated in the pool.

function Get-S2DReserveCalculation {
    <#
    .SYNOPSIS
        Computes recommended reserve space based on node count and largest capacity drive size.

    .PARAMETER NodeCount
        Number of nodes in the cluster.

    .PARAMETER LargestCapacityDriveSizeBytes
        Size in bytes of the largest capacity-tier disk in the cluster.

    .PARAMETER PoolFreeBytes
        Current unallocated bytes remaining in the storage pool.

    .OUTPUTS
        PSCustomObject with ReserveRecommendedBytes, ReserveActualBytes, IsAdequate,
        DriveEquivalentCount, and Status.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $NodeCount,

        [Parameter(Mandatory)]
        [int64] $LargestCapacityDriveSizeBytes,

        [Parameter(Mandatory)]
        [int64] $PoolFreeBytes
    )

    # Recommendation: min(NodeCount, 4) drives worth of unallocated space
    $driveEquivalentCount       = [math]::Min($NodeCount, 4)
    $reserveRecommendedBytes    = $driveEquivalentCount * $LargestCapacityDriveSizeBytes

    $isAdequate = $PoolFreeBytes -ge $reserveRecommendedBytes

    $status = if ($isAdequate) {
        'Adequate'
    } elseif ($PoolFreeBytes -ge ($reserveRecommendedBytes * 0.5)) {
        'Warning'    # Less than recommended but at least half
    } else {
        'Critical'   # Less than half of recommended reserve
    }

    [PSCustomObject]@{
        NodeCount                   = $NodeCount
        DriveEquivalentCount        = $driveEquivalentCount
        LargestCapacityDrive        = [S2DCapacity]::new($LargestCapacityDriveSizeBytes)
        ReserveRecommended          = [S2DCapacity]::new($reserveRecommendedBytes)
        ReserveRecommendedBytes     = $reserveRecommendedBytes
        ReserveActual               = [S2DCapacity]::new($PoolFreeBytes)
        ReserveActualBytes          = $PoolFreeBytes
        ReserveDeficit              = if (-not $isAdequate) { [S2DCapacity]::new($reserveRecommendedBytes - $PoolFreeBytes) } else { $null }
        IsAdequate                  = $isAdequate
        Status                      = $status
    }
}
