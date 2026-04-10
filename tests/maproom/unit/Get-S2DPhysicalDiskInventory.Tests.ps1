#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0'}
BeforeAll {
    $psm1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\S2DCartographer.psm1')
    Import-Module $psm1 -Force
}

Describe 'Get-S2DPhysicalDiskInventory' {

    BeforeEach {
        InModuleScope S2DCartographer {
            $Script:S2DSession = @{
                ClusterName   = 'test-node'
                ClusterFqdn   = $null
                Nodes         = @()
                CimSession    = $null
                PSSession     = $null
                IsConnected   = $true
                IsLocal       = $true
                CollectedData = @{}
            }
        }
    }

    It 'returns enriched disk objects with DiskNumber, latencies, and S2DCapacity size' {
        InModuleScope S2DCartographer {
            $physicalDisks = @(
                [pscustomobject]@{
                    UniqueId          = 'disk-001'
                    FriendlyName      = 'INTEL SSDPE2KX040T8'
                    SerialNumber      = 'SER001'
                    Model             = 'INTEL SSDPE2KX040T8'
                    MediaType         = 'NVMe'
                    BusType           = 'NVMe'
                    FirmwareVersion   = 'VCV10162'
                    Manufacturer      = 'Intel'
                    Usage             = 'Journal'
                    CanPool           = $false
                    HealthStatus      = 'Healthy'
                    OperationalStatus = 'OK'
                    PhysicalLocation  = 'Integrated Port 0'
                    SlotNumber        = 1
                    Size              = [int64]3840000000000
                },
                [pscustomobject]@{
                    UniqueId          = 'disk-002'
                    FriendlyName      = 'SAMSUNG MZ7LH1T9HMLT'
                    SerialNumber      = 'SER002'
                    Model             = 'SAMSUNG MZ7LH1T9HMLT'
                    MediaType         = 'SSD'
                    BusType           = 'SATA'
                    FirmwareVersion   = 'HXT7904Q'
                    Manufacturer      = 'Samsung'
                    Usage             = 'Auto-Select'
                    CanPool           = $false
                    HealthStatus      = 'Healthy'
                    OperationalStatus = 'OK'
                    PhysicalLocation  = 'Integrated Port 1'
                    SlotNumber        = 2
                    Size              = [int64]1920000000000
                }
            )

            Mock Get-S2DPhysicalDiskData { $physicalDisks }

            Mock Get-S2DDiskData {
                @(
                    [pscustomobject]@{ Number = 10; SerialNumber = 'SER001'; BusType = 'NVMe'; Location = 'PCI Slot 10' },
                    [pscustomobject]@{ Number = 11; SerialNumber = 'SER002'; BusType = 'SATA'; Location = 'PCI Slot 11' }
                )
            }

            Mock Get-S2DStorageReliabilityData {
                [pscustomobject]@{
                    Temperature            = 37
                    Wear                   = 12
                    PowerOnHours           = 14892
                    ReadErrorsUncorrected  = 0
                    WriteErrorsUncorrected = 0
                    ReadLatency            = 1.2
                    WriteLatency           = 1.8
                }
            }

            Mock Get-S2DStoragePoolData {
                [pscustomobject]@{ IsPrimordial = $false; FriendlyName = 'S2D on test-node' }
            }

            Mock Get-S2DPoolPhysicalDiskData { $physicalDisks }

            $result = Get-S2DPhysicalDiskInventory

            $result.Count | Should -Be 2
            ($result | Where-Object SerialNumber -eq 'SER001').DiskNumber | Should -Be 10
            ($result | Where-Object SerialNumber -eq 'SER001').Role | Should -Be 'Cache'
            ($result | Where-Object SerialNumber -eq 'SER002').Role | Should -Be 'Capacity'
            ($result | Where-Object SerialNumber -eq 'SER001').ReadLatency | Should -Be 1.2
            ($result | Where-Object SerialNumber -eq 'SER001').WriteLatency | Should -Be 1.8
            ($result | Where-Object SerialNumber -eq 'SER002').Size.GetType().Name | Should -Be 'S2DCapacity'
            ($result | Where-Object SerialNumber -eq 'SER002').PhysicalLocation | Should -Be 'PCI Slot 11'
        }
    }

    It 'warns when capacity sizes, firmware, or health status are inconsistent' {
        InModuleScope S2DCartographer {
            $physicalDisks = @(
                [pscustomobject]@{
                    UniqueId          = 'disk-a'
                    FriendlyName      = 'SAMSUNG PM9A3'
                    SerialNumber      = 'SER-A'
                    Model             = 'SAMSUNG PM9A3'
                    MediaType         = 'NVMe'
                    BusType           = 'NVMe'
                    FirmwareVersion   = 'FW-1'
                    Manufacturer      = 'Samsung'
                    Usage             = 'Auto-Select'
                    CanPool           = $false
                    HealthStatus      = 'Healthy'
                    OperationalStatus = 'OK'
                    PhysicalLocation  = 'Port 1'
                    SlotNumber        = 1
                    Size              = [int64]3840000000000
                },
                [pscustomobject]@{
                    UniqueId          = 'disk-b'
                    FriendlyName      = 'SAMSUNG PM9A3'
                    SerialNumber      = 'SER-B'
                    Model             = 'SAMSUNG PM9A3'
                    MediaType         = 'NVMe'
                    BusType           = 'NVMe'
                    FirmwareVersion   = 'FW-2'
                    Manufacturer      = 'Samsung'
                    Usage             = 'Auto-Select'
                    CanPool           = $false
                    HealthStatus      = 'Warning'
                    OperationalStatus = 'Degraded'
                    PhysicalLocation  = 'Port 2'
                    SlotNumber        = 2
                    Size              = [int64]7680000000000
                }
            )

            Mock Get-S2DPhysicalDiskData { $physicalDisks }

            Mock Get-S2DDiskData {
                @(
                    [pscustomobject]@{ Number = 1; SerialNumber = 'SER-A'; BusType = 'NVMe'; Location = 'Slot 1' },
                    [pscustomobject]@{ Number = 2; SerialNumber = 'SER-B'; BusType = 'NVMe'; Location = 'Slot 2' }
                )
            }

            Mock Get-S2DStorageReliabilityData {
                [pscustomobject]@{
                    Temperature            = 35
                    Wear                   = 10
                    PowerOnHours           = 12000
                    ReadErrorsUncorrected  = 0
                    WriteErrorsUncorrected = 0
                }
            }

            Mock Get-S2DStoragePoolData {
                [pscustomobject]@{ IsPrimordial = $false; FriendlyName = 'S2D on test-node' }
            }

            Mock Get-S2DPoolPhysicalDiskData { $physicalDisks }

            Mock Write-Warning {}

            $null = Get-S2DPhysicalDiskInventory

            Should -Invoke Write-Warning -Scope It -ParameterFilter { $Message -like 'Mixed capacity disk sizes detected*' } -Times 1
            Should -Invoke Write-Warning -Scope It -ParameterFilter { $Message -like 'Firmware inconsistency detected*' } -Times 1
            Should -Invoke Write-Warning -Scope It -ParameterFilter { $Message -like 'Non-healthy disks detected*' } -Times 1
        }
    }
}
