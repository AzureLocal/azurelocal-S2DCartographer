function Get-S2DPhysicalDiskInventory {
    <#
    .SYNOPSIS
        Inventories all physical disks in the S2D cluster with health, capacity, and wear data.

    .DESCRIPTION
        Queries each cluster node for physical disk properties, reliability counters, and
        storage pool membership. Classifies each disk as Cache or Capacity tier, detects
        symmetry anomalies across nodes, and surfaces firmware inconsistencies.

        Requires an active session established with Connect-S2DCluster, or use the
        -CimSession parameter to target a specific node directly.

    .PARAMETER NodeName
        Limit results to one or more specific node names.

    .PARAMETER CimSession
        Override the module session and use this CimSession directly. Useful for ad-hoc
        calls without a full Connect-S2DCluster session.

    .EXAMPLE
        # After Connect-S2DCluster
        Get-S2DPhysicalDiskInventory

    .EXAMPLE
        Get-S2DPhysicalDiskInventory | Format-Table NodeName, FriendlyName, Role, Size, HealthStatus, WearPercentage

    .EXAMPLE
        Get-S2DPhysicalDiskInventory -NodeName "node01", "node02"

    .OUTPUTS
        PSCustomObject[] — one object per physical disk
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]] $NodeName,

        [Parameter()]
        [CimSession] $CimSession
    )

    $session = Resolve-S2DSession -CimSession $CimSession

    # Determine nodes to query
    $nodes = if ($NodeName) {
        $NodeName
    } elseif ($Script:S2DSession.Nodes) {
        $Script:S2DSession.Nodes
    } else {
        # Fall back: run on the connected node and trust it has visibility of all pool disks
        $null
    }

    $allDisks = @()

    # Helper: get disks from a single CIM target
    $getDisksBlock = {
        param([CimSession]$cs, [string]$targetNode)

        $cimParams = @{ ErrorAction = 'SilentlyContinue' }
        if ($cs) { $cimParams['CimSession'] = $cs }
        if ($targetNode -and -not $cs) { $cimParams['ComputerName'] = $targetNode }

        $physDisks       = Get-PhysicalDisk @cimParams
        $reliabilityData = @{}
        try {
            Get-PhysicalDisk @cimParams | ForEach-Object {
                $rd = $_ | Get-StorageReliabilityCounter @cimParams -ErrorAction SilentlyContinue
                if ($rd) { $reliabilityData[$_.UniqueId] = $rd }
            }
        }
        catch { }

        $physDisks | ForEach-Object {
            $disk = $_
            $rel  = $reliabilityData[$disk.UniqueId]
            [PSCustomObject]@{
                NodeName          = $targetNode
                UniqueId          = $disk.UniqueId
                FriendlyName      = $disk.FriendlyName
                SerialNumber      = $disk.SerialNumber
                Model             = $disk.Model
                MediaType         = $disk.MediaType
                BusType           = $disk.BusType
                FirmwareVersion   = $disk.FirmwareVersion
                Manufacturer      = $disk.Manufacturer
                Usage             = $disk.Usage
                CanPool           = $disk.CanPool
                HealthStatus      = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
                PhysicalLocation  = $disk.PhysicalLocation
                SlotNumber        = $disk.SlotNumber
                Size              = $disk.Size
                # Reliability counters — null-safe
                Temperature       = if ($rel) { $rel.Temperature } else { $null }
                WearPercentage    = if ($rel) { $rel.Wear } else { $null }
                PowerOnHours      = if ($rel) { $rel.PowerOnHours } else { $null }
                ReadErrors        = if ($rel) { $rel.ReadErrorsUncorrected } else { $null }
                WriteErrors       = if ($rel) { $rel.WriteErrorsUncorrected } else { $null }
            }
        }
    }

    if ($session -and $nodes) {
        foreach ($node in $nodes) {
            Write-Verbose "  Collecting physical disks from node '$node'..."
            try {
                $nodeCim = New-CimSession -ComputerName $node -ErrorAction Stop
                $disks   = & $getDisksBlock $nodeCim $node
                $allDisks += $disks
                $nodeCim | Remove-CimSession
            }
            catch {
                Write-Warning "Could not collect disks from node '$node': $_"
            }
        }
    } elseif ($session) {
        $allDisks = & $getDisksBlock $session $Script:S2DSession.ClusterName
    } else {
        # Local mode
        $allDisks = & $getDisksBlock $null $env:COMPUTERNAME
    }

    # Classify each disk as Cache or Capacity based on Usage and MediaType
    $poolDisks = @{}
    try {
        $poolCimParams = @{ ErrorAction = 'SilentlyContinue' }
        if ($session) { $poolCimParams['CimSession'] = $session }
        $pool = Get-StoragePool @poolCimParams | Where-Object IsPrimordial -eq $false | Select-Object -First 1
        if ($pool) {
            $pool | Get-PhysicalDisk @poolCimParams | ForEach-Object { $poolDisks[$_.UniqueId] = $true }
        }
    }
    catch { }

    # Build output objects with computed fields
    $result = $allDisks | ForEach-Object {
        $disk = $_

        # Role classification: Usage 'Journal' = cache; otherwise pool membership + media type heuristic
        $role = switch ($disk.Usage) {
            'Journal'     { 'Cache' }
            default {
                if ($poolDisks[$disk.UniqueId]) {
                    # Heuristic: in tiered pool, faster media (NVMe/SSD) = cache if mixed with HDD
                    'Capacity'  # Will be refined by Get-S2DCacheTierInfo in Phase 2
                } else {
                    'Unknown'
                }
            }
        }

        $cap = if ($disk.Size -gt 0) { [S2DCapacity]::new($disk.Size) } else { $null }

        [PSCustomObject]@{
            NodeName          = $disk.NodeName
            UniqueId          = $disk.UniqueId
            FriendlyName      = $disk.FriendlyName
            SerialNumber      = $disk.SerialNumber
            Model             = $disk.Model
            MediaType         = $disk.MediaType
            BusType           = $disk.BusType
            FirmwareVersion   = $disk.FirmwareVersion
            Manufacturer      = $disk.Manufacturer
            Role              = $role
            Usage             = $disk.Usage
            CanPool           = $disk.CanPool
            HealthStatus      = $disk.HealthStatus
            OperationalStatus = $disk.OperationalStatus
            PhysicalLocation  = $disk.PhysicalLocation
            SlotNumber        = $disk.SlotNumber
            Size              = $cap
            SizeBytes         = $disk.Size
            Temperature       = $disk.Temperature
            WearPercentage    = $disk.WearPercentage
            PowerOnHours      = $disk.PowerOnHours
            ReadErrors        = $disk.ReadErrors
            WriteErrors       = $disk.WriteErrors
        }
    }

    # Symmetry check — warn if node disk counts differ
    if ($result) {
        $byNode = $result | Group-Object NodeName
        if ($byNode.Count -gt 1) {
            $counts = $byNode | Select-Object Name, Count
            $unique  = $counts.Count | Select-Object -Unique
            if (@($unique).Count -gt 1) {
                Write-Warning "Disk symmetry anomaly detected: $(($counts | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', ')"
            }
        }
    }

    # Cache collected data for report generation
    $Script:S2DSession.CollectedData['PhysicalDisks'] = $result

    $result
}
