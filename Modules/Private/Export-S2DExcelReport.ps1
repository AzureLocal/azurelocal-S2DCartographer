# Excel report exporter — uses ImportExcel module

function Export-S2DExcelReport {
    param(
        [Parameter(Mandatory)] [S2DClusterData] $ClusterData,
        [Parameter(Mandatory)] [string]          $OutputPath,
        [string] $Author  = '',
        [string] $Company = ''
    )

    if (-not (Get-Module -ListAvailable -Name ImportExcel -ErrorAction SilentlyContinue)) {
        throw "The 'ImportExcel' module is required for Excel reports. Install it with: Install-Module ImportExcel -Scope CurrentUser"
    }
    Import-Module ImportExcel -ErrorAction Stop

    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

    $wf    = $ClusterData.CapacityWaterfall
    $pool  = $ClusterData.StoragePool
    $vols  = @($ClusterData.Volumes)
    $disks = @($ClusterData.PhysicalDisks)
    $hc    = @($ClusterData.HealthChecks)

    # ── Tab 1: Summary ────────────────────────────────────────────────────────
    $summary = [PSCustomObject]@{
        ClusterName          = $ClusterData.ClusterName
        NodeCount            = $ClusterData.NodeCount
        CollectedAt          = $ClusterData.CollectedAt
        OverallHealth        = $ClusterData.OverallHealth
        RawCapacityTiB       = if ($wf) { $wf.RawCapacity.TiB }       else { 'N/A' }
        RawCapacityTB        = if ($wf) { $wf.RawCapacity.TB }        else { 'N/A' }
        UsableCapacityTiB    = if ($wf) { $wf.UsableCapacity.TiB }    else { 'N/A' }
        UsableCapacityTB     = if ($wf) { $wf.UsableCapacity.TB }     else { 'N/A' }
        ReserveStatus        = if ($wf) { $wf.ReserveStatus }         else { 'N/A' }
        BlendedEfficiency    = if ($wf) { "$($wf.BlendedEfficiencyPercent)%" } else { 'N/A' }
        PoolFriendlyName     = if ($pool) { $pool.FriendlyName }      else { 'N/A' }
        PoolHealthStatus     = if ($pool) { $pool.HealthStatus }       else { 'N/A' }
        PoolTotalTiB         = if ($pool -and $pool.TotalSize)    { $pool.TotalSize.TiB }    else { 'N/A' }
        PoolAllocatedTiB     = if ($pool -and $pool.AllocatedSize){ $pool.AllocatedSize.TiB } else { 'N/A' }
        PoolRemainingTiB     = if ($pool -and $pool.RemainingSize){ $pool.RemainingSize.TiB } else { 'N/A' }
        OvercommitRatio      = if ($pool) { $pool.OvercommitRatio }    else { 'N/A' }
        Author               = $Author
        Company              = $Company
    }
    $summary | Export-Excel -Path $OutputPath -WorksheetName 'Summary' -AutoSize -FreezeTopRow -BoldTopRow

    # ── Tab 2: Capacity Waterfall ─────────────────────────────────────────────
    if ($wf) {
        $wfData = $wf.Stages | ForEach-Object {
            [PSCustomObject]@{
                Stage       = $_.Stage
                Name        = $_.Name
                SizeTiB     = if ($_.Size) { $_.Size.TiB } else { 0 }
                SizeTB      = if ($_.Size) { $_.Size.TB }  else { 0 }
                SizeBytes   = if ($_.Size) { $_.Size.Bytes } else { 0 }
                DeltaTiB    = if ($_.Delta) { $_.Delta.TiB } else { $null }
                Description = $_.Description
                Status      = $_.Status
            }
        }
        $wfData | Export-Excel -Path $OutputPath -WorksheetName 'Capacity Waterfall' -AutoSize -FreezeTopRow -BoldTopRow -Append
    }

    # ── Tab 3: Physical Disks ─────────────────────────────────────────────────
    $diskData = $disks | ForEach-Object {
        [PSCustomObject]@{
            NodeName          = $_.NodeName
            FriendlyName      = $_.FriendlyName
            SerialNumber      = $_.SerialNumber
            MediaType         = $_.MediaType
            BusType           = $_.BusType
            Role              = $_.Role
            SizeTiB           = if ($_.Size) { $_.Size.TiB } else { 0 }
            SizeTB            = if ($_.Size) { $_.Size.TB }  else { 0 }
            Model             = $_.Model
            FirmwareVersion   = $_.FirmwareVersion
            HealthStatus      = $_.HealthStatus
            OperationalStatus = $_.OperationalStatus
            WearPercentage    = $_.WearPercentage
            Temperature       = $_.Temperature
            PowerOnHours      = $_.PowerOnHours
            ReadErrors        = $_.ReadErrors
            WriteErrors       = $_.WriteErrors
        }
    }
    $diskData | Export-Excel -Path $OutputPath -WorksheetName 'Physical Disks' -AutoSize -FreezeTopRow -BoldTopRow -Append

    # ── Tab 4: Storage Pool ───────────────────────────────────────────────────
    if ($pool) {
        $poolData = [PSCustomObject]@{
            FriendlyName         = $pool.FriendlyName
            HealthStatus         = $pool.HealthStatus
            OperationalStatus    = $pool.OperationalStatus
            IsReadOnly           = $pool.IsReadOnly
            TotalSizeTiB         = if ($pool.TotalSize)      { $pool.TotalSize.TiB }       else { 0 }
            AllocatedSizeTiB     = if ($pool.AllocatedSize)  { $pool.AllocatedSize.TiB }   else { 0 }
            RemainingSizeTiB     = if ($pool.RemainingSize)  { $pool.RemainingSize.TiB }   else { 0 }
            ProvisionedSizeTiB   = if ($pool.ProvisionedSize){ $pool.ProvisionedSize.TiB } else { 0 }
            OvercommitRatio      = $pool.OvercommitRatio
            FaultDomainAwareness = $pool.FaultDomainAwareness
        }
        $poolData | Export-Excel -Path $OutputPath -WorksheetName 'Storage Pool' -AutoSize -FreezeTopRow -BoldTopRow -Append
    }

    # ── Tab 5: Volumes ────────────────────────────────────────────────────────
    $volData = $vols | ForEach-Object {
        [PSCustomObject]@{
            FriendlyName            = $_.FriendlyName
            FileSystem              = $_.FileSystem
            ResiliencySettingName   = $_.ResiliencySettingName
            NumberOfDataCopies      = $_.NumberOfDataCopies
            ProvisioningType        = $_.ProvisioningType
            SizeTiB                 = if ($_.Size)            { $_.Size.TiB }            else { 0 }
            FootprintOnPoolTiB      = if ($_.FootprintOnPool) { $_.FootprintOnPool.TiB } else { 0 }
            AllocatedSizeTiB        = if ($_.AllocatedSize)   { $_.AllocatedSize.TiB }   else { 0 }
            EfficiencyPercent       = $_.EfficiencyPercent
            HealthStatus            = $_.HealthStatus
            OperationalStatus       = $_.OperationalStatus
            IsDeduplicationEnabled  = $_.IsDeduplicationEnabled
            IsInfrastructureVolume  = $_.IsInfrastructureVolume
        }
    }
    $volData | Export-Excel -Path $OutputPath -WorksheetName 'Volumes' -AutoSize -FreezeTopRow -BoldTopRow -Append

    # ── Tab 6: Health Checks ──────────────────────────────────────────────────
    $hcData = $hc | ForEach-Object {
        [PSCustomObject]@{
            CheckName   = $_.CheckName
            Severity    = $_.Severity
            Status      = $_.Status
            Details     = $_.Details
            Remediation = $_.Remediation
        }
    }
    $hcData | Export-Excel -Path $OutputPath -WorksheetName 'Health Checks' -AutoSize -FreezeTopRow -BoldTopRow -Append

    # ── Tab 7: Raw Data (JSON) ────────────────────────────────────────────────
    $rawJson = $ClusterData | ConvertTo-Json -Depth 8 -Compress
    [PSCustomObject]@{ RawJson = $rawJson } |
        Export-Excel -Path $OutputPath -WorksheetName 'Raw Data' -AutoSize -Append

    Write-Verbose "Excel report written to $OutputPath"
    $OutputPath
}
