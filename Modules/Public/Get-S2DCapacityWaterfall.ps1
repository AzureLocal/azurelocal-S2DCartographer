function Get-S2DCapacityWaterfall {
    <#
    .SYNOPSIS
        Computes the 8-stage theoretical capacity waterfall from raw physical to final usable capacity.

    .DESCRIPTION
        Performs the complete S2D best-practice capacity accounting pipeline. Every stage
        is a theoretical deduction — the model assumes you start with a clean pool and
        apply each recommended overhead in sequence. No live provisioned-volume state
        influences the pipeline.

          Stage 1  Raw physical capacity — pool-member capacity-tier disks only (cache excluded)
          Stage 2  Vendor TB label note — informational only; no bytes deducted
          Stage 3  After storage pool overhead (~1%)
          Stage 4  After reserve space (min(NodeCount,4) × largest capacity drive)
          Stage 5  After infrastructure volume (Azure Local infra CSV)
          Stage 6  Available for workload volumes
          Stage 7  After resiliency overhead (theoretical; uses pool default resiliency or 3-way mirror)
          Stage 8  Final usable capacity (pipeline terminus — equals Stage 7)

        Uses data already collected by the other Get-S2D* cmdlets when available,
        or runs the collectors itself.

    .EXAMPLE
        Get-S2DCapacityWaterfall

    .EXAMPLE
        Get-S2DCapacityWaterfall | Select-Object -ExpandProperty Stages | Format-Table

    .OUTPUTS
        S2DCapacityWaterfall
    #>
    [CmdletBinding()]
    [OutputType([S2DCapacityWaterfall])]
    param()

    # ── Gather prerequisite data from cache or live queries ───────────────────
    $physDisks = @($Script:S2DSession.CollectedData['PhysicalDisks'])
    if (-not $physDisks) {
        Write-Verbose "Collecting physical disk data for waterfall."
        $physDisks = @(Get-S2DPhysicalDiskInventory)
    }

    $pool = $Script:S2DSession.CollectedData['StoragePool']
    if (-not $pool) {
        Write-Verbose "Collecting storage pool data for waterfall."
        $pool = Get-S2DStoragePoolInfo
    }

    $volumes = @($Script:S2DSession.CollectedData['Volumes'])
    if (-not $volumes) {
        Write-Verbose "Collecting volume data for waterfall."
        $volumes = @(Get-S2DVolumeMap)
    }

    $nodeCount = if ($Script:S2DSession.Nodes.Count -gt 0) { $Script:S2DSession.Nodes.Count } else {
        # Estimate from disk symmetry
        $perNode = @($physDisks | Group-Object NodeName)
        if ($perNode.Count -gt 0) { $perNode.Count } else { 4 }
    }

    # ── Stage 1: Raw physical capacity ────────────────────────────────────────
    # Pool-member capacity-tier disks only. Non-pool disks (BOSS boot drives,
    # SAN-presented LUNs) are excluded — they are not part of the S2D pool and
    # including them inflates Stage 1 far above what the pool actually sees.
    $capacityDisks = @($physDisks | Where-Object { $_.IsPoolMember -ne $false -and $_.Role -eq 'Capacity' })
    if (-not $capacityDisks) {
        # Fall back: pool-member non-Journal/non-Retired disks
        $capacityDisks = @($physDisks | Where-Object {
            $_.IsPoolMember -ne $false -and
            $_.Usage -ne 'Journal' -and
            $_.Usage -ne 'Retired'
        })
    }

    $stage1Bytes     = [int64]($capacityDisks | Measure-Object -Property SizeBytes -Sum).Sum
    $largestDriveBytes = [int64]($capacityDisks | Measure-Object -Property SizeBytes -Maximum).Maximum

    # ── Stage 2: TB-label note ────────────────────────────────────────────────
    # Informational only — no bytes deducted. Vendor labels drives in decimal
    # (1 TB = 1,000,000,000,000 bytes); Windows reports binary TiB. The same raw
    # bytes are interpreted differently depending on which unit system you use.
    $vendorLabeledTB = [math]::Round($stage1Bytes / 1000000000000, 2)
    $stage2Bytes     = $stage1Bytes   # no change — display note only

    # ── Stage 3: Pool overhead (~1%) ──────────────────────────────────────────
    $poolTotalBytes = if ($pool -and $pool.TotalSize) { $pool.TotalSize.Bytes } else { $stage2Bytes }
    $stage3Bytes    = $poolTotalBytes

    # ── Stage 4: Reserve space ────────────────────────────────────────────────
    $reserveCalc  = Get-S2DReserveCalculation -NodeCount $nodeCount `
                        -LargestCapacityDriveSizeBytes $largestDriveBytes `
                        -PoolFreeBytes ($pool ? $pool.RemainingSize.Bytes : 0)

    $reserveBytes = $reserveCalc.ReserveRecommendedBytes
    $stage4Bytes  = $stage3Bytes - $reserveBytes

    # ── Stage 5: Infrastructure volume ───────────────────────────────────────
    $infraVolumes = @($volumes | Where-Object IsInfrastructureVolume)
    $infraBytes   = [int64]0
    foreach ($iv in $infraVolumes) {
        if ($iv.FootprintOnPool) { $infraBytes += $iv.FootprintOnPool.Bytes }
        elseif ($iv.Size)        { $infraBytes += $iv.Size.Bytes }
    }
    $stage5Bytes = $stage4Bytes - $infraBytes

    # ── Stage 6: Available for workload volumes ───────────────────────────────
    $stage6Bytes = $stage5Bytes

    # ── Stage 7: Theoretical resiliency overhead ──────────────────────────────
    # Purely theoretical — applies the pool's configured default resiliency factor
    # to Stage 6 (available pool space). No live provisioned-volume data is used.
    # Default: 3-way mirror (S2D best practice for 3+ nodes, most conservative).
    # Overridden by pool ResiliencySettings if the Mirror entry is present.
    $resiliencyFactor = 3.0
    $resiliencyName   = '3-way mirror'
    if ($pool -and $pool.ResiliencySettings) {
        $mirrorSetting = @($pool.ResiliencySettings | Where-Object { $_.Name -eq 'Mirror' }) | Select-Object -First 1
        if ($mirrorSetting -and $mirrorSetting.NumberOfDataCopies -gt 0) {
            $resiliencyFactor = [double]$mirrorSetting.NumberOfDataCopies
            $resiliencyName   = "$($mirrorSetting.NumberOfDataCopies)-way mirror"
        }
    }
    $stage7Bytes  = [int64]($stage6Bytes / $resiliencyFactor)
    $theoreticalEfficiencyPct = [math]::Round(100.0 / $resiliencyFactor, 1)

    # ── Stage 8: Final usable capacity ────────────────────────────────────────
    # Pipeline terminus. No further theoretical deductions beyond resiliency.
    $stage8Bytes = $stage7Bytes

    # ── Overcommit detection ──────────────────────────────────────────────────
    $isOvercommitted = $pool -and $pool.OvercommitRatio -gt 1.0
    $overcommitRatio = if ($pool) { $pool.OvercommitRatio } else { 0.0 }

    # ── Build stage objects ───────────────────────────────────────────────────
    function local:New-WaterfallStage {
        param([int]$Stage, [string]$Name, [int64]$Bytes, [int64]$PrevBytes, [string]$Description, [string]$Status = 'OK')
        $s = [S2DWaterfallStage]::new()
        $s.Stage       = $Stage
        $s.Name        = $Name
        $s.Size        = if ($Bytes -gt 0) { [S2DCapacity]::new($Bytes) } else { [S2DCapacity]::new([int64]0) }
        $s.Delta       = if ($PrevBytes -gt $Bytes -and $PrevBytes -gt 0) { [S2DCapacity]::new($PrevBytes - $Bytes) } else { $null }
        $s.Description = $Description
        $s.Status      = $Status
        $s
    }

    $reserveStatus = $reserveCalc.Status
    $stage4Status  = switch ($reserveStatus) { 'Adequate' { 'OK' } 'Warning' { 'Warning' } default { 'Critical' } }

    $stages = @(
        (New-WaterfallStage 1 'Raw Physical'          $stage1Bytes $stage1Bytes   "Sum of pool-member capacity-tier disk sizes ($($capacityDisks.Count) drives, $('{0:N2}' -f ($largestDriveBytes/1TB)) TB each)"),
        (New-WaterfallStage 2 'Vendor Label (TB)'     $stage2Bytes $stage1Bytes   "Informational — vendor labels drives in decimal TB; Windows reports binary TiB. Vendor label: $vendorLabeledTB TB. No bytes deducted."),
        (New-WaterfallStage 3 'Pool (after overhead)' $stage3Bytes $stage2Bytes   "Storage pool overhead (~1%). Pool total: $(if($pool){"$($pool.TotalSize.TiB) TiB"} else {"N/A"})"),
        (New-WaterfallStage 4 'After Reserve'         $stage4Bytes $stage3Bytes   "Reserve: min($nodeCount,4) × $('{0:N2}' -f ($largestDriveBytes/1TB)) TB = $('{0:N2}' -f ($reserveBytes/1TB)) TB" $stage4Status),
        (New-WaterfallStage 5 'After Infra Volume'    $stage5Bytes $stage4Bytes   "Infrastructure volume footprint: $(if($infraBytes -gt 0){"$([math]::Round($infraBytes/1073741824,1)) GiB"} else {"None detected"})"),
        (New-WaterfallStage 6 'Available'             $stage6Bytes $stage5Bytes   "Pool space available for workload volumes"),
        (New-WaterfallStage 7 'After Resiliency'      $stage7Bytes $stage6Bytes   "Theoretical resiliency overhead ($resiliencyName, $theoreticalEfficiencyPct% efficiency). Available ÷ $resiliencyFactor."),
        (New-WaterfallStage 8 'Final Usable'          $stage8Bytes $stage7Bytes   "Pipeline terminus — no further theoretical deductions. Usable VM and workload capacity under $resiliencyName resiliency.")
    )

    $waterfall = [S2DCapacityWaterfall]::new()
    $waterfall.Stages                   = $stages
    $waterfall.RawCapacity              = [S2DCapacity]::new($stage1Bytes)
    $waterfall.UsableCapacity           = if ($stage8Bytes -gt 0) { [S2DCapacity]::new($stage8Bytes) } else { [S2DCapacity]::new([int64]0) }
    $waterfall.ReserveRecommended       = $reserveCalc.ReserveRecommended
    $waterfall.ReserveActual            = $reserveCalc.ReserveActual
    $waterfall.ReserveStatus            = $reserveStatus
    $waterfall.IsOvercommitted          = $isOvercommitted
    $waterfall.OvercommitRatio          = $overcommitRatio
    $waterfall.NodeCount                = $nodeCount
    $waterfall.BlendedEfficiencyPercent = $theoreticalEfficiencyPct

    $Script:S2DSession.CollectedData['CapacityWaterfall'] = $waterfall
    $waterfall
}
