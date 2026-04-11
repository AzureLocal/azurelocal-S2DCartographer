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

    function local:Get-S2DNormalizedText {
        param($Value)

        if ($null -eq $Value) { return $null }

        $text = [string]$Value
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        return $text.Trim().ToUpperInvariant()
    }

    function local:Get-S2DFirstValue {
        param(
            $InputObject,
            [string[]] $PropertyNames
        )

        if (-not $InputObject) { return $null }

        foreach ($propertyName in $PropertyNames) {
            $property = $InputObject.PSObject.Properties[$propertyName]
            if (-not $property) { continue }

            $value = $property.Value
            if ($null -eq $value) { continue }
            if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { continue }

            return $value
        }

        return $null
    }

    function local:Get-S2DDiskLookupKeys {
        param($Disk)

        $keys = @()
        $uniqueId = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('UniqueId'))
        $serial = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('SerialNumber'))
        $friendlyName = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('FriendlyName'))
        $sizeBytes = Get-S2DFirstValue $Disk @('Size', 'SizeBytes')

        if ($uniqueId) { $keys += "UniqueId::$uniqueId" }
        if ($serial) { $keys += "Serial::$serial" }
        if ($friendlyName -and $null -ne $sizeBytes) {
            $keys += "NameSize::$friendlyName::$sizeBytes"
        }

        return $keys
    }

    function local:Get-S2DMediaRank {
        param([string] $MediaType)

        switch ($MediaType) {
            'SCM' { return 4 }
            'NVMe' { return 3 }
            'SSD' { return 2 }
            'HDD' { return 1 }
            default { return 0 }
        }
    }

    $usePSSession = -not $PSBoundParameters.ContainsKey('CimSession') -and -not $Script:S2DSession.IsLocal -and $null -ne $Script:S2DSession.PSSession
    $session = if ($usePSSession) { $null } else { Resolve-S2DSession -CimSession $CimSession }

    # Determine nodes to query
    $nodes = if ($NodeName) {
        $NodeName
    }
    elseif ($Script:S2DSession.Nodes) {
        $Script:S2DSession.Nodes
    }
    else {
        # Fall back: run on the connected node and trust it has visibility of all pool disks
        $null
    }

    $allDisks = @()

    # Helper: get disks from a single CIM target
    $getDisksBlock = {
        param([CimSession]$cs, [string]$targetNode)

        $physDisks = if ($cs) {
            @(Get-S2DPhysicalDiskData -CimSession $cs)
        }
        else {
            @(Get-S2DPhysicalDiskData)
        }
        $diskLookup = @{}

        try {
            @(if ($cs) { Get-S2DDiskData -CimSession $cs } else { Get-S2DDiskData }) | ForEach-Object {
                foreach ($key in (Get-S2DDiskLookupKeys $_)) {
                    if (-not $diskLookup.ContainsKey($key)) {
                        $diskLookup[$key] = $_
                    }
                }
            }
        }
        catch { }

        $physDisks | ForEach-Object {
            $disk = $_
            $diskDetail = $null
            foreach ($key in (Get-S2DDiskLookupKeys $disk)) {
                if ($diskLookup.ContainsKey($key)) {
                    $diskDetail = $diskLookup[$key]
                    break
                }
            }

            $rel = $null
            try {
                $rel = if ($cs) {
                    $disk | Get-S2DStorageReliabilityData -CimSession $cs
                }
                else {
                    $disk | Get-S2DStorageReliabilityData
                }
            }
            catch { }

            $busType = Get-S2DFirstValue $diskDetail @('BusType')
            if (-not $busType) { $busType = $disk.BusType }

            $physicalLocation = Get-S2DFirstValue $diskDetail @('PhysicalLocation', 'Location', 'LocationPath', 'Path')
            if (-not $physicalLocation) { $physicalLocation = $disk.PhysicalLocation }

            $slotNumber = Get-S2DFirstValue $diskDetail @('SlotNumber', 'LocationNumber')
            if ($null -eq $slotNumber) { $slotNumber = $disk.SlotNumber }

            [PSCustomObject]@{
                NodeName          = $targetNode
                DiskNumber        = Get-S2DFirstValue $diskDetail @('Number', 'DiskNumber')
                UniqueId          = $disk.UniqueId
                FriendlyName      = $disk.FriendlyName
                SerialNumber      = $disk.SerialNumber
                Model             = $disk.Model
                MediaType         = $disk.MediaType
                BusType           = $busType
                FirmwareVersion   = $disk.FirmwareVersion
                Manufacturer      = $disk.Manufacturer
                Usage             = $disk.Usage
                CanPool           = $disk.CanPool
                HealthStatus      = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
                PhysicalLocation  = $physicalLocation
                SlotNumber        = $slotNumber
                SizeBytes         = $disk.Size
                # Reliability counters — null-safe
                Temperature       = if ($rel) { $rel.Temperature } else { $null }
                WearPercentage    = if ($rel) { $rel.Wear } else { $null }
                PowerOnHours      = if ($rel) { $rel.PowerOnHours } else { $null }
                ReadErrors        = if ($rel) { $rel.ReadErrorsUncorrected } else { $null }
                WriteErrors       = if ($rel) { $rel.WriteErrorsUncorrected } else { $null }
                ReadLatency       = if ($rel) { Get-S2DFirstValue $rel @('ReadLatency', 'AverageReadLatency', 'ReadLatencyMax', 'ReadLatencyMs') } else { $null }
                WriteLatency      = if ($rel) { Get-S2DFirstValue $rel @('WriteLatency', 'AverageWriteLatency', 'WriteLatencyMax', 'WriteLatencyMs') } else { $null }
            }
        }
    }

    $getDisksFromPSSessionBlock = {
        param($psSession)

        Invoke-Command -Session $psSession -ScriptBlock {
            function Get-S2DNormalizedText {
                param($Value)

                if ($null -eq $Value) { return $null }
                $text = [string]$Value
                if ([string]::IsNullOrWhiteSpace($text)) { return $null }

                return $text.Trim().ToUpperInvariant()
            }

            function Get-S2DFirstValue {
                param(
                    $InputObject,
                    [string[]] $PropertyNames
                )

                if (-not $InputObject) { return $null }

                foreach ($propertyName in $PropertyNames) {
                    $property = $InputObject.PSObject.Properties[$propertyName]
                    if (-not $property) { continue }

                    $value = $property.Value
                    if ($null -eq $value) { continue }
                    if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { continue }

                    return $value
                }

                return $null
            }

            function Get-S2DDiskLookupKeys {
                param($Disk)

                $keys = @()
                $uniqueId = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('UniqueId'))
                $serial = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('SerialNumber'))
                $friendlyName = Get-S2DNormalizedText (Get-S2DFirstValue $Disk @('FriendlyName'))
                $sizeBytes = Get-S2DFirstValue $Disk @('Size', 'SizeBytes')

                if ($uniqueId) { $keys += "UniqueId::$uniqueId" }
                if ($serial) { $keys += "Serial::$serial" }
                if ($friendlyName -and $null -ne $sizeBytes) {
                    $keys += "NameSize::$friendlyName::$sizeBytes"
                }

                return $keys
            }

            $targetNode = $env:COMPUTERNAME
            $physDisks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue)
            $diskLookup = @{}

            try {
                @(Get-Disk -ErrorAction SilentlyContinue) | ForEach-Object {
                    foreach ($key in (Get-S2DDiskLookupKeys $_)) {
                        if (-not $diskLookup.ContainsKey($key)) {
                            $diskLookup[$key] = $_
                        }
                    }
                }
            }
            catch { }

            $physDisks | ForEach-Object {
                $disk = $_
                $diskDetail = $null
                foreach ($key in (Get-S2DDiskLookupKeys $disk)) {
                    if ($diskLookup.ContainsKey($key)) {
                        $diskDetail = $diskLookup[$key]
                        break
                    }
                }

                $rel = $null
                try {
                    $rel = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                }
                catch { }

                $busType = Get-S2DFirstValue $diskDetail @('BusType')
                if (-not $busType) { $busType = $disk.BusType }

                $physicalLocation = Get-S2DFirstValue $diskDetail @('PhysicalLocation', 'Location', 'LocationPath', 'Path')
                if (-not $physicalLocation) { $physicalLocation = $disk.PhysicalLocation }

                $slotNumber = Get-S2DFirstValue $diskDetail @('SlotNumber', 'LocationNumber')
                if ($null -eq $slotNumber) { $slotNumber = $disk.SlotNumber }

                [PSCustomObject]@{
                    NodeName          = $targetNode
                    DiskNumber        = Get-S2DFirstValue $diskDetail @('Number', 'DiskNumber')
                    UniqueId          = $disk.UniqueId
                    FriendlyName      = $disk.FriendlyName
                    SerialNumber      = $disk.SerialNumber
                    Model             = $disk.Model
                    MediaType         = $disk.MediaType
                    BusType           = $busType
                    FirmwareVersion   = $disk.FirmwareVersion
                    Manufacturer      = $disk.Manufacturer
                    Usage             = $disk.Usage
                    CanPool           = $disk.CanPool
                    HealthStatus      = $disk.HealthStatus
                    OperationalStatus = $disk.OperationalStatus
                    PhysicalLocation  = $physicalLocation
                    SlotNumber        = $slotNumber
                    SizeBytes         = $disk.Size
                    Temperature       = if ($rel) { $rel.Temperature } else { $null }
                    WearPercentage    = if ($rel) { $rel.Wear } else { $null }
                    PowerOnHours      = if ($rel) { $rel.PowerOnHours } else { $null }
                    ReadErrors        = if ($rel) { $rel.ReadErrorsUncorrected } else { $null }
                    WriteErrors       = if ($rel) { $rel.WriteErrorsUncorrected } else { $null }
                    ReadLatency       = if ($rel) { Get-S2DFirstValue $rel @('ReadLatency', 'AverageReadLatency', 'ReadLatencyMax', 'ReadLatencyMs') } else { $null }
                    WriteLatency      = if ($rel) { Get-S2DFirstValue $rel @('WriteLatency', 'AverageWriteLatency', 'WriteLatencyMax', 'WriteLatencyMs') } else { $null }
                }
            }
        }
    }

    if ($usePSSession) {
        $allDisks = & $getDisksFromPSSessionBlock $Script:S2DSession.PSSession
    }
    elseif ($session -and $nodes) {
        foreach ($node in $nodes) {
            Write-Verbose "  Collecting physical disks from node '$node'..."
            try {
                $nodeCimParams = @{
                    ComputerName   = $node
                    Authentication = ($Script:S2DSession.Authentication ?? 'Negotiate')
                    ErrorAction    = 'Stop'
                }
                if ($Script:S2DSession.Credential) {
                    $nodeCimParams['Credential'] = $Script:S2DSession.Credential
                }
                $nodeCim = New-CimSession @nodeCimParams
                $disks = & $getDisksBlock $nodeCim $node
                $allDisks += $disks
                $nodeCim | Remove-CimSession
            }
            catch {
                Write-Warning "Could not collect disks from node '$node': $_"
            }
        }
    }
    elseif ($session) {
        $allDisks = & $getDisksBlock $session $Script:S2DSession.ClusterName
    }
    else {
        # Local mode
        $allDisks = & $getDisksBlock $null $env:COMPUTERNAME
    }

    if ($NodeName) {
        $allDisks = @($allDisks | Where-Object { $_.NodeName -in $NodeName })
    }

    # Classify each disk as Cache or Capacity based on Usage and MediaType
    $poolDisks = @{}
    try {
        $poolPhysicalDisks = if ($usePSSession) {
            Invoke-Command -Session $Script:S2DSession.PSSession -ScriptBlock {
                $pool = Get-StoragePool -ErrorAction SilentlyContinue | Where-Object IsPrimordial -eq $false | Select-Object -First 1
                if ($pool) {
                    $pool | Get-PhysicalDisk -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            $pool = if ($session) {
                Get-S2DStoragePoolData -CimSession $session | Where-Object IsPrimordial -eq $false | Select-Object -First 1
            }
            else {
                Get-S2DStoragePoolData | Where-Object IsPrimordial -eq $false | Select-Object -First 1
            }

            if ($pool) {
                if ($session) {
                    Get-S2DPoolPhysicalDiskData -StoragePool $pool -CimSession $session
                }
                else {
                    Get-S2DPoolPhysicalDiskData -StoragePool $pool
                }
            }
        }

        foreach ($poolDisk in @($poolPhysicalDisks)) {
            foreach ($key in (Get-S2DDiskLookupKeys $poolDisk)) {
                $poolDisks[$key] = $true
            }
        }
    }
    catch { }

    $poolMediaRanks = @(
        $allDisks |
        Where-Object {
            foreach ($key in (Get-S2DDiskLookupKeys $_)) {
                if ($poolDisks.ContainsKey($key)) { return $true }
            }

            return $false
        } |
        ForEach-Object { Get-S2DMediaRank $_.MediaType } |
        Where-Object { $_ -gt 0 }
    )

    $highestPoolMediaRank = if ($poolMediaRanks) { ($poolMediaRanks | Measure-Object -Maximum).Maximum } else { 0 }
    $lowestPoolMediaRank = if ($poolMediaRanks) { ($poolMediaRanks | Measure-Object -Minimum).Minimum } else { 0 }

    # Build output objects with computed fields
    $result = $allDisks | ForEach-Object {
        $disk = $_

        $inPool = $false
        foreach ($key in (Get-S2DDiskLookupKeys $disk)) {
            if ($poolDisks.ContainsKey($key)) {
                $inPool = $true
                break
            }
        }

        # Role classification: Usage 'Journal' = cache; otherwise pool membership + media type heuristic
        $role = switch ($disk.Usage) {
            'Journal' { 'Cache' }
            default {
                if ($inPool) {
                    $mediaRank = Get-S2DMediaRank $disk.MediaType
                    if ($highestPoolMediaRank -gt $lowestPoolMediaRank -and $mediaRank -eq $highestPoolMediaRank) {
                        'Cache'
                    }
                    else {
                        'Capacity'
                    }
                }
                else {
                    'Unknown'
                }
            }
        }

        $cap = if ($disk.SizeBytes -gt 0) { [S2DCapacity]::new($disk.SizeBytes) } else { $null }

        [PSCustomObject]@{
            NodeName          = $disk.NodeName
            DiskNumber        = $disk.DiskNumber
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
            SizeBytes         = $disk.SizeBytes
            Temperature       = $disk.Temperature
            WearPercentage    = $disk.WearPercentage
            PowerOnHours      = $disk.PowerOnHours
            ReadErrors        = $disk.ReadErrors
            WriteErrors       = $disk.WriteErrors
            ReadLatency       = $disk.ReadLatency
            WriteLatency      = $disk.WriteLatency
        }
    }

    # Surface inventory anomalies directly in the collector output path.
    if ($result) {
        $byNode = $result | Group-Object NodeName
        if ($byNode.Count -gt 1) {
            $counts = $byNode | Select-Object Name, Count
            $uniqueCounts = @($counts | Select-Object -ExpandProperty Count | Select-Object -Unique)
            if ($uniqueCounts.Count -gt 1) {
                Write-Warning "Disk symmetry anomaly detected: $(($counts | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', ')"
            }
        }

        $capacitySizes = @(
            $result |
            Where-Object Role -eq 'Capacity' |
            Select-Object -ExpandProperty SizeBytes |
            Where-Object { $_ -gt 0 } |
            Select-Object -Unique
        )
        if ($capacitySizes.Count -gt 1) {
            Write-Warning "Mixed capacity disk sizes detected: $($capacitySizes -join ', ')"
        }

        $firmwareByModel = $result | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Model) } | Group-Object Model
        foreach ($modelGroup in $firmwareByModel) {
            $firmwareVersions = @(
                $modelGroup.Group |
                Select-Object -ExpandProperty FirmwareVersion |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
            )

            if ($firmwareVersions.Count -gt 1) {
                Write-Warning "Firmware inconsistency detected for model '$($modelGroup.Name)': $($firmwareVersions -join ', ')"
            }
        }

        $nonHealthyDisks = @(
            $result |
            Where-Object {
                $_.HealthStatus -ne 'Healthy' -or (
                    $null -ne $_.OperationalStatus -and
                    [string]$_.OperationalStatus -notin @('OK', 'Healthy')
                )
            }
        )
        if ($nonHealthyDisks.Count -gt 0) {
            $labels = $nonHealthyDisks | ForEach-Object { "$($_.NodeName)/$($_.FriendlyName) [$($_.HealthStatus)]" }
            Write-Warning "Non-healthy disks detected: $($labels -join ', ')"
        }
    }

    # Cache collected data for report generation
    $Script:S2DSession.CollectedData['PhysicalDisks'] = $result

    $result
}
