#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0'}
BeforeAll {
    $psm1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\S2DCartographer.psm1')
    Import-Module $psm1 -Force
}

Describe 'Get-S2DReserveCalculation' {

    Context 'DriveEquivalentCount caps at 4 nodes' {
        It 'NodeCount=1 => DriveEquivalentCount=1' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 1 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).DriveEquivalentCount | Should -Be 1
            }
        }
        It 'NodeCount=2 => DriveEquivalentCount=2' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 2 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).DriveEquivalentCount | Should -Be 2
            }
        }
        It 'NodeCount=4 => DriveEquivalentCount=4' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).DriveEquivalentCount | Should -Be 4
            }
        }
        It 'NodeCount=8 => capped at 4' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 8 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).DriveEquivalentCount | Should -Be 4
            }
        }
        It 'NodeCount=16 => capped at 4' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 16 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).DriveEquivalentCount | Should -Be 4
            }
        }
    }

    Context 'ReserveRecommendedBytes calculation' {
        It 'NodeCount=1, 3.84 TB disk => 3840000000000 bytes recommended' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 1 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).ReserveRecommendedBytes | Should -Be 3840000000000
            }
        }
        It 'NodeCount=4, 3.84 TB disk => 15360000000000 bytes recommended' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).ReserveRecommendedBytes | Should -Be 15360000000000
            }
        }
        It 'NodeCount=16 (capped) => same as NodeCount=4: 15360000000000 bytes' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 16 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).ReserveRecommendedBytes | Should -Be 15360000000000
            }
        }
        It 'NodeCount=3, 1.92 TB disk => 5760000000000 bytes recommended' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]1920000000000) -PoolFreeBytes ([int64]20000000000000)).ReserveRecommendedBytes | Should -Be 5760000000000
            }
        }
    }

    Context 'Status = Adequate (free >= recommended)' {
        It 'free equals recommended => Adequate' {
            InModuleScope S2DCartographer {
                $rec = [int64](3840000000000 * 3)
                $r = Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes $rec
                $r.Status     | Should -Be 'Adequate'
                $r.IsAdequate | Should -BeTrue
            }
        }
        It 'free exceeds recommended => Adequate' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)
                $r.Status     | Should -Be 'Adequate'
                $r.IsAdequate | Should -BeTrue
            }
        }
        It 'IsAdequate=true => ReserveDeficit is null' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 2 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]10000000000000)
                $r.IsAdequate     | Should -BeTrue
                $r.ReserveDeficit | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Status = Warning (50% <= free < recommended)' {
        It '3-node: free=7TB, recommended=11.52TB => Warning' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]7000000000000)
                $r.Status     | Should -Be 'Warning'
                $r.IsAdequate | Should -BeFalse
            }
        }
        It 'free exactly at 50% threshold => Warning (not Critical)' {
            InModuleScope S2DCartographer {
                $halfRec = [int64]((3840000000000 * 3) / 2)
                (Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes $halfRec).Status | Should -Be 'Warning'
            }
        }
        It 'Warning => ReserveDeficit is populated' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]7000000000000)
                $r.ReserveDeficit | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Status = Critical (free < 50% of recommended)' {
        It '3-node: free=2TB is Critical' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]2000000000000)
                $r.Status     | Should -Be 'Critical'
                $r.IsAdequate | Should -BeFalse
            }
        }
        It 'PoolFreeBytes=0 => Critical' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]0)).Status | Should -Be 'Critical'
            }
        }
        It 'Critical => ReserveDeficit.Bytes = recommended - free' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 3 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]2000000000000)
                $r.ReserveDeficit.Bytes | Should -Be ([int64](3840000000000 * 3 - 2000000000000))
            }
        }
    }

    Context 'Output object shape' {
        It 'returns PSCustomObject' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)
                $r | Should -BeOfType ([PSCustomObject])
            }
        }
        It 'ReserveRecommended and ReserveActual are S2DCapacity objects' {
            InModuleScope S2DCartographer {
                $r = Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)
                $r.ReserveRecommended.GetType().Name | Should -Be 'S2DCapacity'; $r.ReserveActual.GetType().Name | Should -Be 'S2DCapacity'
            }
        }
        It 'ReserveActualBytes = PoolFreeBytes' {
            InModuleScope S2DCartographer {
                $free = [int64]12345678901234
                (Get-S2DReserveCalculation -NodeCount 4 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes $free).ReserveActualBytes | Should -Be $free
            }
        }
        It 'NodeCount property echoes input' {
            InModuleScope S2DCartographer {
                (Get-S2DReserveCalculation -NodeCount 7 -LargestCapacityDriveSizeBytes ([int64]3840000000000) -PoolFreeBytes ([int64]20000000000000)).NodeCount | Should -Be 7
            }
        }
    }
}
