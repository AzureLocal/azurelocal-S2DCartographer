#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0'}
BeforeAll {
    $psm1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\S2DCartographer.psm1')
    Import-Module $psm1 -Force
}

Describe 'Get-S2DCapacityWaterfall' {

    BeforeEach {
        InModuleScope S2DCartographer {
            # IIC 4-node, 4× 3.84TB NVMe per node — all capacity disks
            $physDisks = @(foreach ($node in 1..4) {
                foreach ($disk in 1..4) {
                    [PSCustomObject]@{
                        NodeName  = "azl-iic-n0$node"
                        Role      = 'Capacity'
                        Usage     = 'Auto-Select'
                        SizeBytes = [int64]3840000000000
                    }
                }
            })

            # Pool: 16 × 3.84TB = 61.44TB raw → pool with slight overhead
            $poolTotal  = [int64]60820000000000   # ~60.82 TB
            $poolFree   = [int64]40820000000000   # ~40.82 TB free (adequate reserve)
            $poolAlloc  = $poolTotal - $poolFree

            $pool = [S2DStoragePool]::new()
            $pool.TotalSize      = [S2DCapacity]::new($poolTotal)
            $pool.AllocatedSize  = [S2DCapacity]::new($poolAlloc)
            $pool.RemainingSize  = [S2DCapacity]::new($poolFree)
            $pool.OvercommitRatio = 0.10

            # 1 infra + 2 workload volumes
            $iv = [S2DVolume]::new()
            $iv.FriendlyName           = 'Infrastructure_aabbccddeeff'
            $iv.IsInfrastructureVolume = $true
            $iv.Size                   = [S2DCapacity]::new([int64]524288000000)    # 512 GiB
            $iv.FootprintOnPool        = [S2DCapacity]::new([int64]1572864000000)   # 1.5 TiB 3-way footprint
            $iv.EfficiencyPercent      = 33.3

            $wv1 = [S2DVolume]::new()
            $wv1.FriendlyName           = 'UserStorage_1'
            $wv1.IsInfrastructureVolume = $false
            $wv1.Size                   = [S2DCapacity]::new([int64]3000000000000)  # 3 TB
            $wv1.FootprintOnPool        = [S2DCapacity]::new([int64]9000000000000)  # 9 TB (3-way)
            $wv1.EfficiencyPercent      = 33.3

            $wv2 = [S2DVolume]::new()
            $wv2.FriendlyName           = 'UserStorage_2'
            $wv2.IsInfrastructureVolume = $false
            $wv2.Size                   = [S2DCapacity]::new([int64]3000000000000)
            $wv2.FootprintOnPool        = [S2DCapacity]::new([int64]9000000000000)
            $wv2.EfficiencyPercent      = 33.3

            $Script:S2DSession = @{
                ClusterName   = 'azlocal-iic-s2d-01'
                ClusterFqdn   = 'azlocal-iic-s2d-01.iic.local'
                Nodes         = @('azl-iic-n01','azl-iic-n02','azl-iic-n03','azl-iic-n04')
                CimSession    = $null
                PSSession     = $null
                IsConnected   = $true
                IsLocal       = $true
                CollectedData = @{
                    PhysicalDisks = $physDisks
                    StoragePool   = $pool
                    Volumes       = @($iv, $wv1, $wv2)
                }
            }
        }
    }

    Context 'Return type and structure' {
        It 'returns an S2DCapacityWaterfall object' {
            InModuleScope S2DCartographer {
                $result = Get-S2DCapacityWaterfall
                $result                | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'S2DCapacityWaterfall'
            }
        }

        It 'produces exactly 8 stages' {
            InModuleScope S2DCartographer {
                (Get-S2DCapacityWaterfall).Stages.Count | Should -Be 8
            }
        }

        It 'stages are numbered 1 through 8 in order' {
            InModuleScope S2DCartographer {
                $i = 1
                foreach ($stage in (Get-S2DCapacityWaterfall).Stages) {
                    $stage.Stage | Should -Be $i
                    $i++
                }
            }
        }

        It 'RawCapacity and UsableCapacity are S2DCapacity objects' {
            InModuleScope S2DCartographer {
                $result = Get-S2DCapacityWaterfall
                $result.RawCapacity.GetType().Name    | Should -Be 'S2DCapacity'
                $result.UsableCapacity.GetType().Name | Should -Be 'S2DCapacity'
            }
        }

        It 'ReserveRecommended and ReserveActual are S2DCapacity objects' {
            InModuleScope S2DCartographer {
                $result = Get-S2DCapacityWaterfall
                $result.ReserveRecommended.GetType().Name | Should -Be 'S2DCapacity'
                $result.ReserveActual.GetType().Name      | Should -Be 'S2DCapacity'
            }
        }

        It 'NodeCount matches session node count' {
            InModuleScope S2DCartographer {
                (Get-S2DCapacityWaterfall).NodeCount | Should -Be 4
            }
        }
    }

    Context 'Stage calculations' {
        It 'Stage 1 (Raw Physical) equals sum of all capacity disk bytes' {
            InModuleScope S2DCartographer {
                $expected = [int64](16 * 3840000000000)   # 16 disks × 3.84 TB
                (Get-S2DCapacityWaterfall).Stages[0].Size.Bytes | Should -Be $expected
            }
        }

        It 'Stage 3 (Pool) uses pool.TotalSize when pool data is present' {
            InModuleScope S2DCartographer {
                (Get-S2DCapacityWaterfall).Stages[2].Size.Bytes | Should -Be ([int64]60820000000000)
            }
        }

        It 'Stage 4 (After Reserve) equals Stage 3 minus min(NodeCount,4) × largest drive' {
            InModuleScope S2DCartographer {
                $poolTotal    = [int64]60820000000000
                $reserveBytes = [int64](4 * 3840000000000)   # 4 × 3.84 TB = 15.36 TB
                $expected     = $poolTotal - $reserveBytes
                (Get-S2DCapacityWaterfall).Stages[3].Size.Bytes | Should -Be $expected
            }
        }

        It 'Stage 8 (Final Usable) equals sum of workload volume sizes' {
            InModuleScope S2DCartographer {
                $expected = [int64](2 * 3000000000000)   # 2 workload volumes × 3 TB
                (Get-S2DCapacityWaterfall).Stages[7].Size.Bytes | Should -Be $expected
            }
        }
    }

    Context 'Reserve status' {
        It 'ReserveStatus is Adequate when pool free space exceeds recommendation' {
            InModuleScope S2DCartographer {
                # poolFree=40.82TB >> reserve=15.36TB
                (Get-S2DCapacityWaterfall).ReserveStatus | Should -Be 'Adequate'
            }
        }

        It 'ReserveStatus is Critical when pool free space is critically low' {
            InModuleScope S2DCartographer {
                # Override pool to have very little free space
                $pool = $Script:S2DSession.CollectedData['StoragePool']
                $pool.RemainingSize = [S2DCapacity]::new([int64]3000000000000)   # 3 TB << 15.36 TB reserve

                (Get-S2DCapacityWaterfall).ReserveStatus | Should -Be 'Critical'
            }
        }

        It 'Stage 4 Status is OK when reserve is Adequate' {
            InModuleScope S2DCartographer {
                (Get-S2DCapacityWaterfall).Stages[3].Status | Should -Be 'OK'
            }
        }

        It 'Stage 4 Status is Critical when reserve is critically low' {
            InModuleScope S2DCartographer {
                $pool = $Script:S2DSession.CollectedData['StoragePool']
                $pool.RemainingSize = [S2DCapacity]::new([int64]3000000000000)

                (Get-S2DCapacityWaterfall).Stages[3].Status | Should -Be 'Critical'
            }
        }
    }

    Context 'Caching' {
        It 'caches result in CollectedData after computation' {
            InModuleScope S2DCartographer {
                Get-S2DCapacityWaterfall | Out-Null
                $Script:S2DSession.CollectedData['CapacityWaterfall']                | Should -Not -BeNullOrEmpty
                $Script:S2DSession.CollectedData['CapacityWaterfall'].GetType().Name | Should -Be 'S2DCapacityWaterfall'
            }
        }
    }
}
