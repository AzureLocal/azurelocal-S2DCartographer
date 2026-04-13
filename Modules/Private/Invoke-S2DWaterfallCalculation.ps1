# Invoke-S2DWaterfallCalculation — pure waterfall math, no session dependency.
# Called by Get-S2DCapacityWaterfall (live cluster) and Invoke-S2DCapacityWhatIf (what-if modeling).

function Invoke-S2DWaterfallCalculation {
    <#
    .SYNOPSIS
        Computes the 8-stage S2D capacity waterfall from explicit numeric inputs.

    .DESCRIPTION
        Pure function — no PowerShell session, no module state, no live CIM queries.
        All inputs are passed explicitly. Returns an S2DCapacityWaterfall object.

        Stage 1  Raw physical capacity (pool-member capacity disks)
        Stage 2  Vendor TB label note (informational — no bytes deducted)
        Stage 3  After storage pool overhead
        Stage 4  After reserve space (min(NodeCount,4) × largest drive)
        Stage 5  After infrastructure volume
        Stage 6  Available for workload volumes
        Stage 7  After resiliency overhead (theoretical)
        Stage 8  Final usable capacity (pipeline terminus = Stage 7)

    .PARAMETER RawDiskBytes
        Sum of all pool-member capacity-tier disk sizes in bytes (Stage 1).

    .PARAMETER NodeCount
        Number of nodes in the cluster. Used for reserve calculation.

    .PARAMETER LargestDiskSizeBytes
        Size in bytes of the largest capacity-tier disk. Used for reserve calculation.

    .PARAMETER PoolTotalBytes
        Storage pool total size in bytes (Stage 3). If 0, estimated as
        RawDiskBytes × (1 - PoolOverheadFraction).

    .PARAMETER PoolFreeBytes
        Current unallocated pool bytes. Used for reserve status only (Adequate/Warning/Critical).
        Does not affect stage values.

    .PARAMETER PoolOverheadFraction
        Pool overhead as a fraction (default 0.01 = 1%). Used only when PoolTotalBytes is 0.

    .PARAMETER InfraVolumeBytes
        Infrastructure volume pool footprint in bytes (Stage 5 deduction).

    .PARAMETER ResiliencyFactor
        Number of data copies for resiliency (default 3.0 for 3-way mirror).
        Stage 7 = Stage 6 / ResiliencyFactor.

    .PARAMETER ResiliencyName
        Human-readable label for the resiliency type (default '3-way mirror').
    #>
    [CmdletBinding()]
    [OutputType([S2DCapacityWaterfall])]
    param(
        [Parameter(Mandatory)]
        [int64]  $RawDiskBytes,

        [Parameter(Mandatory)]
        [int]    $NodeCount,

        [Parameter(Mandatory)]
        [int64]  $LargestDiskSizeBytes,

        [int64]  $PoolTotalBytes        = 0,
        [int64]  $PoolFreeBytes         = 0,
        [double] $PoolOverheadFraction  = 0.01,
        [int64]  $InfraVolumeBytes      = 0,
        [double] $ResiliencyFactor      = 3.0,
        [string] $ResiliencyName        = '3-way mirror'
    )

    # ── Stage 1: Raw physical ─────────────────────────────────────────────────
    $stage1Bytes = $RawDiskBytes

    # ── Stage 2: Vendor TB label note (no deduction) ─────────────────────────
    $vendorLabeledTB = [math]::Round($stage1Bytes / 1000000000000, 2)
    $stage2Bytes     = $stage1Bytes

    # ── Stage 3: Pool overhead ────────────────────────────────────────────────
    $stage3Bytes = if ($PoolTotalBytes -gt 0) {
        $PoolTotalBytes
    } else {
        [int64]($stage2Bytes * (1.0 - $PoolOverheadFraction))
    }

    # ── Stage 4: Reserve space ────────────────────────────────────────────────
    $reserveCalc  = Get-S2DReserveCalculation `
        -NodeCount                    $NodeCount `
        -LargestCapacityDriveSizeBytes $LargestDiskSizeBytes `
        -PoolFreeBytes                $PoolFreeBytes
    $reserveBytes = $reserveCalc.ReserveRecommendedBytes
    $stage4Bytes  = $stage3Bytes - $reserveBytes

    # ── Stage 5: Infrastructure volume ───────────────────────────────────────
    $stage5Bytes = $stage4Bytes - $InfraVolumeBytes

    # ── Stage 6: Available ────────────────────────────────────────────────────
    $stage6Bytes = $stage5Bytes

    # ── Stage 7: Theoretical resiliency ──────────────────────────────────────
    $stage7Bytes = [int64]($stage6Bytes / $ResiliencyFactor)
    $theoreticalEffPct = [math]::Round(100.0 / $ResiliencyFactor, 1)

    # ── Stage 8: Final usable (pipeline terminus) ─────────────────────────────
    $stage8Bytes = $stage7Bytes

    # ── Build stage objects ───────────────────────────────────────────────────
    function local:New-Stage {
        param([int]$N, [string]$Name, [int64]$Bytes, [int64]$Prev, [string]$Desc, [string]$Status = 'OK')
        $s = [S2DWaterfallStage]::new()
        $s.Stage       = $N
        $s.Name        = $Name
        $s.Size        = if ($Bytes -gt 0) { [S2DCapacity]::new($Bytes) } else { [S2DCapacity]::new([int64]0) }
        $s.Delta       = if ($Prev -gt $Bytes -and $Prev -gt 0) { [S2DCapacity]::new($Prev - $Bytes) } else { $null }
        $s.Description = $Desc
        $s.Status      = $Status
        $s
    }

    $stage4Status = switch ($reserveCalc.Status) { 'Adequate' { 'OK' } 'Warning' { 'Warning' } default { 'Critical' } }

    $driveCount   = if ($LargestDiskSizeBytes -gt 0) { [math]::Round($RawDiskBytes / $LargestDiskSizeBytes) } else { 0 }
    $infraDisplay = if ($InfraVolumeBytes -gt 0) { "$([math]::Round($InfraVolumeBytes/1073741824,1)) GiB" } else { 'None detected' }

    $stages = @(
        (New-Stage 1 'Raw Physical'           $stage1Bytes $stage1Bytes   "Sum of pool-member capacity-tier disk sizes ($driveCount drives, $('{0:N2}' -f ($LargestDiskSizeBytes/1TB)) TB each)"),
        (New-Stage 2 'Vendor Label (TB)'      $stage2Bytes $stage1Bytes   "Informational — vendor labels drives in decimal TB; Windows reports binary TiB. Vendor label: $vendorLabeledTB TB. No bytes deducted."),
        (New-Stage 3 'Pool (after overhead)'  $stage3Bytes $stage2Bytes   "Storage pool overhead (~$([math]::Round($PoolOverheadFraction*100,0))%). Pool total: $('{0:N2}' -f ($stage3Bytes/1TB)) TB"),
        (New-Stage 4 'After Reserve'          $stage4Bytes $stage3Bytes   "Reserve: min($NodeCount,4) × $('{0:N2}' -f ($LargestDiskSizeBytes/1TB)) TB = $('{0:N2}' -f ($reserveBytes/1TB)) TB" $stage4Status),
        (New-Stage 5 'After Infra Volume'     $stage5Bytes $stage4Bytes   "Infrastructure volume footprint: $infraDisplay"),
        (New-Stage 6 'Available'              $stage6Bytes $stage5Bytes   "Pool space available for workload volumes"),
        (New-Stage 7 'After Resiliency'       $stage7Bytes $stage6Bytes   "Theoretical resiliency overhead ($ResiliencyName, $theoreticalEffPct% efficiency). Available ÷ $ResiliencyFactor."),
        (New-Stage 8 'Final Usable'           $stage8Bytes $stage7Bytes   "Pipeline terminus — no further theoretical deductions. Usable VM and workload capacity under $ResiliencyName resiliency.")
    )

    $wf = [S2DCapacityWaterfall]::new()
    $wf.Stages                   = $stages
    $wf.RawCapacity              = [S2DCapacity]::new($stage1Bytes)
    $wf.UsableCapacity           = if ($stage8Bytes -gt 0) { [S2DCapacity]::new($stage8Bytes) } else { [S2DCapacity]::new([int64]0) }
    $wf.ReserveRecommended       = $reserveCalc.ReserveRecommended
    $wf.ReserveActual            = $reserveCalc.ReserveActual
    $wf.ReserveStatus            = $reserveCalc.Status
    $wf.IsOvercommitted          = $false
    $wf.OvercommitRatio          = 0.0
    $wf.NodeCount                = $NodeCount
    $wf.BlendedEfficiencyPercent = $theoreticalEffPct
    $wf
}
