function Get-S2DPhysicalDiskData {
    param(
        [CimSession] $CimSession
    )

    if ($PSBoundParameters.ContainsKey('CimSession')) {
        Get-PhysicalDisk -CimSession $CimSession -ErrorAction SilentlyContinue
        return
    }

    Get-PhysicalDisk -ErrorAction SilentlyContinue
}

function Get-S2DDiskData {
    param(
        [CimSession] $CimSession
    )

    if ($PSBoundParameters.ContainsKey('CimSession')) {
        Get-Disk -CimSession $CimSession -ErrorAction SilentlyContinue
        return
    }

    Get-Disk -ErrorAction SilentlyContinue
}

function Get-S2DStorageReliabilityData {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        $PhysicalDisk,

        [CimSession] $CimSession
    )

    process {
        if ($PSBoundParameters.ContainsKey('CimSession')) {
            $PhysicalDisk | Get-StorageReliabilityCounter -CimSession $CimSession -ErrorAction SilentlyContinue
            return
        }

        $PhysicalDisk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    }
}

function Get-S2DStoragePoolData {
    param(
        [CimSession] $CimSession
    )

    if ($PSBoundParameters.ContainsKey('CimSession')) {
        Get-StoragePool -CimSession $CimSession -ErrorAction SilentlyContinue
        return
    }

    Get-StoragePool -ErrorAction SilentlyContinue
}

function Get-S2DPoolPhysicalDiskData {
    param(
        [Parameter(Mandatory)]
        $StoragePool,

        [CimSession] $CimSession
    )

    if ($PSBoundParameters.ContainsKey('CimSession')) {
        $StoragePool | Get-PhysicalDisk -CimSession $CimSession -ErrorAction SilentlyContinue
        return
    }

    $StoragePool | Get-PhysicalDisk -ErrorAction SilentlyContinue
}
