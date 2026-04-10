#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0'}
BeforeAll {
    $psm1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\S2DCartographer.psm1')
    Import-Module $psm1 -Force
}

Describe 'Get-S2DHealthStatus' {

    BeforeEach {
        InModuleScope S2DCartographer {
            # 4-node IIC all-NVMe cluster, all healthy and symmetric
            $physDisks = @(foreach ($node in 1..4) {
                foreach ($disk in 1..4) {
                    [PSCustomObject]@{
                        NodeName          = "azl-iic-n0$node"
                        FriendlyName      = 'INTEL SSDPE2KX040T8'
                        SerialNumber      = "IIC01N0${node}D$disk"
                        MediaType         = 'NVMe'
                        Model             = 'INTEL SSDPE2KX040T8'
                        FirmwareVersion   = 'VCV10162'
                        HealthStatus      = 'Healthy'
                        OperationalStatus = 'OK'
                        Role              = 'Capacity'
                        SizeBytes         = [int64]3840000000000
                        WearPercentage    = 10
                    }
                }
            })

            $pool = [S2DStoragePool]::new()
            $pool.FriendlyName      = 'S2D on azlocal-iic-s2d-01'
            $pool.HealthStatus      = 'Healthy'
            $pool.OperationalStatus = 'OK'
            $pool.IsReadOnly        = $false
            $pool.TotalSize         = [S2DCapacity]::new([int64]60820000000000)
            $pool.AllocatedSize     = [S2DCapacity]::new([int64]20000000000000)
            $pool.RemainingSize     = [S2DCapacity]::new([int64]40820000000000)
            $pool.ProvisionedSize   = [S2DCapacity]::new([int64]6000000000000)
            $pool.OvercommitRatio   = 0.099

            $vol1 = [S2DVolume]::new()
            $vol1.FriendlyName           = 'UserStorage_1'
            $vol1.HealthStatus           = 'Healthy'
            $vol1.OperationalStatus      = 'OK'
            $vol1.IsInfrastructureVolume = $false
            $vol1.EfficiencyPercent      = 33.3
            $vol1.Size                   = [S2DCapacity]::new([int64]3000000000000)
            $vol1.FootprintOnPool        = [S2DCapacity]::new([int64]9000000000000)

            $vol2 = [S2DVolume]::new()
            $vol2.FriendlyName           = 'Infrastructure_aabbccddeeff00112233445566778899'
            $vol2.HealthStatus           = 'Healthy'
            $vol2.OperationalStatus      = 'OK'
            $vol2.IsInfrastructureVolume = $true
            $vol2.EfficiencyPercent      = 33.3
            $vol2.Size                   = [S2DCapacity]::new([int64]524288000000)
            $vol2.FootprintOnPool        = [S2DCapacity]::new([int64]1572864000000)

            $cache = [S2DCacheTier]::new()
            $cache.IsAllFlash           = $true
            $cache.SoftwareCacheEnabled = $true
            $cache.CacheMode            = 'ReadWrite'
            $cache.CacheState           = 'Active'
            $cache.CacheDiskCount       = 0

            $wf = [S2DCapacityWaterfall]::new()
            $wf.ReserveActual      = [S2DCapacity]::new([int64]40820000000000)
            $wf.ReserveRecommended = [S2DCapacity]::new([int64]15360000000000)
            $wf.ReserveStatus      = 'Adequate'
            $wf.IsOvercommitted    = $false

            $Script:S2DSession = @{
                ClusterName   = 'azlocal-iic-s2d-01'
                ClusterFqdn   = 'azlocal-iic-s2d-01.iic.local'
                Nodes         = @('azl-iic-n01','azl-iic-n02','azl-iic-n03','azl-iic-n04')
                CimSession    = $null
                PSSession     = $null
                IsConnected   = $true
                IsLocal       = $true
                CollectedData = @{
                    PhysicalDisks     = $physDisks
                    StoragePool       = $pool
                    Volumes           = @($vol1, $vol2)
                    CacheTier         = $cache
                    CapacityWaterfall = $wf
                }
            }
        }
    }

    Context 'Output shape' {
        It 'returns exactly 10 S2DHealthCheck objects on a healthy cluster' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                $result.Count | Should -Be 10
                $result | ForEach-Object { $_.GetType().Name | Should -Be 'S2DHealthCheck' }
            }
        }

        It 'all 10 checks contain non-empty CheckName, Severity, Status, and Details' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                $result | ForEach-Object {
                    $_.CheckName | Should -Not -BeNullOrEmpty
                    $_.Severity  | Should -Not -BeNullOrEmpty
                    $_.Status    | Should -Not -BeNullOrEmpty
                    $_.Details   | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'filters results when -CheckName specifies a subset' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus -CheckName 'DiskHealth', 'NVMeWear'
                $result.Count | Should -Be 2
                $result.CheckName | Should -Contain 'DiskHealth'
                $result.CheckName | Should -Contain 'NVMeWear'
            }
        }
    }

    Context 'Healthy cluster — all checks pass' {
        It 'all checks are Pass on the healthy IIC cluster' {
            InModuleScope S2DCartographer {
                $failing = @(Get-S2DHealthStatus | Where-Object { $_.Status -ne 'Pass' })
                $failing.Count | Should -Be 0
            }
        }

        It 'sets OverallHealth to Healthy in CollectedData' {
            InModuleScope S2DCartographer {
                Get-S2DHealthStatus | Out-Null
                $Script:S2DSession.CollectedData['OverallHealth'] | Should -Be 'Healthy'
            }
        }

        It 'InfrastructureVolume passes when infra volume is healthy' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'InfrastructureVolume').Status | Should -Be 'Pass'
            }
        }

        It 'CacheTierHealth passes for all-flash software-cache cluster' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'CacheTierHealth').Status | Should -Be 'Pass'
            }
        }

        It 'DiskSymmetry passes when all nodes have equal disk counts' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'DiskSymmetry').Status | Should -Be 'Pass'
            }
        }

        It 'DiskHealth passes when all disks are Healthy' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'DiskHealth').Status | Should -Be 'Pass'
            }
        }

        It 'NVMeWear passes when all drives are below 80% wear' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'NVMeWear').Status | Should -Be 'Pass'
            }
        }
    }

    Context 'DiskSymmetry check' {
        It 'warns when one node has fewer disks than peers' {
            InModuleScope S2DCartographer {
                $disks = @($Script:S2DSession.CollectedData['PhysicalDisks'])
                $Script:S2DSession.CollectedData['PhysicalDisks'] = @(
                    $disks | Where-Object { -not ($_.NodeName -eq 'azl-iic-n04' -and $_.SerialNumber -in 'IIC01N04D3','IIC01N04D4') }
                )
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'DiskSymmetry').Status | Should -Be 'Warn'
            }
        }
    }

    Context 'DiskHealth check' {
        It 'fails when any physical disk is non-healthy' {
            InModuleScope S2DCartographer {
                $disks = @($Script:S2DSession.CollectedData['PhysicalDisks'])
                $degraded = [PSCustomObject]@{
                    NodeName          = $disks[0].NodeName
                    FriendlyName      = $disks[0].FriendlyName
                    SerialNumber      = $disks[0].SerialNumber
                    MediaType         = 'NVMe'
                    Model             = $disks[0].Model
                    FirmwareVersion   = $disks[0].FirmwareVersion
                    Role              = 'Capacity'
                    SizeBytes         = $disks[0].SizeBytes
                    WearPercentage    = 10
                    HealthStatus      = 'Warning'
                    OperationalStatus = 'Degraded'
                }
                $Script:S2DSession.CollectedData['PhysicalDisks'] = @($degraded) + @($disks | Select-Object -Skip 1)

                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'DiskHealth').Status | Should -Be 'Fail'
            }
        }
    }

    Context 'NVMeWear check' {
        It 'warns when an NVMe drive exceeds 80% wear' {
            InModuleScope S2DCartographer {
                $disks = @($Script:S2DSession.CollectedData['PhysicalDisks'])
                $worn = [PSCustomObject]@{
                    NodeName          = $disks[0].NodeName
                    FriendlyName      = $disks[0].FriendlyName
                    SerialNumber      = $disks[0].SerialNumber
                    MediaType         = 'NVMe'
                    Model             = $disks[0].Model
                    FirmwareVersion   = $disks[0].FirmwareVersion
                    Role              = 'Capacity'
                    SizeBytes         = $disks[0].SizeBytes
                    WearPercentage    = 85
                    HealthStatus      = 'Healthy'
                    OperationalStatus = 'OK'
                }
                $Script:S2DSession.CollectedData['PhysicalDisks'] = @($worn) + @($disks | Select-Object -Skip 1)

                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'NVMeWear').Status | Should -Be 'Warn'
            }
        }
    }

    Context 'ReserveAdequacy check' {
        It 'passes when waterfall ReserveStatus is Adequate' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'ReserveAdequacy').Status | Should -Be 'Pass'
            }
        }

        It 'warns when waterfall ReserveStatus is Warning' {
            InModuleScope S2DCartographer {
                $Script:S2DSession.CollectedData['CapacityWaterfall'].ReserveStatus = 'Warning'
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'ReserveAdequacy').Status | Should -Be 'Warn'
            }
        }

        It 'fails when waterfall ReserveStatus is Critical' {
            InModuleScope S2DCartographer {
                $Script:S2DSession.CollectedData['CapacityWaterfall'].ReserveStatus = 'Critical'
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'ReserveAdequacy').Status | Should -Be 'Fail'
            }
        }
    }

    Context 'OverallHealth rollup' {
        It 'is Critical when a Critical-severity check has Status Fail' {
            InModuleScope S2DCartographer {
                $Script:S2DSession.CollectedData['CapacityWaterfall'].ReserveStatus = 'Critical'
                Get-S2DHealthStatus | Out-Null
                $Script:S2DSession.CollectedData['OverallHealth'] | Should -Be 'Critical'
            }
        }

        It 'is Warning when only Warning-severity checks are non-Pass' {
            InModuleScope S2DCartographer {
                $Script:S2DSession.CollectedData['CacheTier'].CacheState = 'Degraded'
                Get-S2DHealthStatus | Out-Null
                $Script:S2DSession.CollectedData['OverallHealth'] | Should -Be 'Warning'
            }
        }
    }

    Context 'FirmwareConsistency check' {
        It 'warns when drives of the same model have different firmware versions' {
            InModuleScope S2DCartographer {
                $disks = @($Script:S2DSession.CollectedData['PhysicalDisks'])
                $mixed = [PSCustomObject]@{
                    NodeName          = $disks[0].NodeName
                    FriendlyName      = $disks[0].FriendlyName
                    SerialNumber      = $disks[0].SerialNumber
                    MediaType         = 'NVMe'
                    Model             = 'INTEL SSDPE2KX040T8'
                    FirmwareVersion   = 'VCV10999'   # different from 'VCV10162'
                    Role              = 'Capacity'
                    SizeBytes         = $disks[0].SizeBytes
                    WearPercentage    = 10
                    HealthStatus      = 'Healthy'
                    OperationalStatus = 'OK'
                }
                $Script:S2DSession.CollectedData['PhysicalDisks'] = @($mixed) + @($disks | Select-Object -Skip 1)

                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'FirmwareConsistency').Status | Should -Be 'Warn'
            }
        }

        It 'passes when all drives of the same model share the same firmware' {
            InModuleScope S2DCartographer {
                $result = Get-S2DHealthStatus
                ($result | Where-Object CheckName -eq 'FirmwareConsistency').Status | Should -Be 'Pass'
            }
        }
    }
}
