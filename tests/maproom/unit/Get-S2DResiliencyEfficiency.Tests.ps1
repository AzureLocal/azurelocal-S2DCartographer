#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0'}
BeforeAll {
    $psm1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\S2DCartographer.psm1')
    Import-Module $psm1 -Force
}

Describe 'Get-S2DResiliencyEfficiency' {

    Context 'Mirror - Two-Way (NumberOfDataCopies=2, NodeCount > 2)' {
        It 'ResiliencyType = "Two-Way Mirror"' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 3).ResiliencyType | Should -Be 'Two-Way Mirror'
            }
        }
        It 'efficiency = 50.0%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 3).EfficiencyPercent | Should -Be 50.0
            }
        }
        It '4-node still 50.0%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 4).EfficiencyPercent | Should -Be 50.0
            }
        }
        It '8-node still 50.0%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 8).EfficiencyPercent | Should -Be 50.0
            }
        }
    }

    Context 'Mirror - Nested Two-Way (NumberOfDataCopies=2, NodeCount <= 2)' {
        It '2-node: ResiliencyType = "Nested Two-Way Mirror"' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 2).ResiliencyType | Should -Be 'Nested Two-Way Mirror'
            }
        }
        It '2-node: efficiency = 25.0%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 2).EfficiencyPercent | Should -Be 25.0
            }
        }
        It '1-node: also returns Nested Two-Way Mirror' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 1).ResiliencyType | Should -Be 'Nested Two-Way Mirror'
            }
        }
    }

    Context 'Mirror - Three-Way (NumberOfDataCopies=3)' {
        It 'ResiliencyType = "Three-Way Mirror"' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 3 -NodeCount 3).ResiliencyType | Should -Be 'Three-Way Mirror'
            }
        }
        It 'efficiency = 33.3%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 3 -NodeCount 3).EfficiencyPercent | Should -Be 33.3
            }
        }
        It '4-node three-way still 33.3%' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 3 -NodeCount 4).EfficiencyPercent | Should -Be 33.3
            }
        }
    }

    Context 'Parity - Single (PhysicalDiskRedundancy=1)' {
        It 'ResiliencyType = "Single Parity"' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 1 -NodeCount 3).ResiliencyType | Should -Be 'Single Parity'
            }
        }
        It '3-node single parity: efficiency = 66.7%  ((3-1)/3 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 1 -NodeCount 3).EfficiencyPercent | Should -Be 66.7
            }
        }
        It '4-node single parity: efficiency = 75.0%  ((4-1)/4 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 1 -NodeCount 4).EfficiencyPercent | Should -Be 75.0
            }
        }
        It '8-node single parity: efficiency = 87.5%  ((8-1)/8 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 1 -NodeCount 8).EfficiencyPercent | Should -Be 87.5
            }
        }
    }

    Context 'Parity - Dual (PhysicalDiskRedundancy=2)' {
        It 'ResiliencyType = "Dual Parity"' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 4).ResiliencyType | Should -Be 'Dual Parity'
            }
        }
        It '4-node dual parity: efficiency = 50.0%  ((4-2)/4 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 4).EfficiencyPercent | Should -Be 50.0
            }
        }
        It '6-node dual parity: efficiency = 66.7%  ((6-2)/6 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 6).EfficiencyPercent | Should -Be 66.7
            }
        }
        It '8-node dual parity: efficiency = 75.0%  ((8-2)/8 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 8).EfficiencyPercent | Should -Be 75.0
            }
        }
        It '16-node dual parity: efficiency = 87.5%  ((16-2)/16 * 100)' {
            InModuleScope S2DCartographer {
                (Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 16).EfficiencyPercent | Should -Be 87.5
            }
        }
    }

    Context 'Output object shape' {
        It 'returns PSCustomObject' {
            InModuleScope S2DCartographer {
                $r = Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 3 -NodeCount 4
                $r | Should -BeOfType ([PSCustomObject])
            }
        }
        It 'has ResiliencyType, EfficiencyPercent, Description properties' {
            InModuleScope S2DCartographer {
                $r = Get-S2DResiliencyEfficiency -ResiliencySettingName Mirror -NumberOfDataCopies 2 -NodeCount 4
                $r.PSObject.Properties.Name | Should -Contain 'ResiliencyType'
                $r.PSObject.Properties.Name | Should -Contain 'EfficiencyPercent'
                $r.PSObject.Properties.Name | Should -Contain 'Description'
            }
        }
        It 'Description is a non-empty string' {
            InModuleScope S2DCartographer {
                $r = Get-S2DResiliencyEfficiency -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NodeCount 6
                $r.Description | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'ValidateSet enforcement' {
        It 'throws on invalid ResiliencySettingName' {
            InModuleScope S2DCartographer {
                { Get-S2DResiliencyEfficiency -ResiliencySettingName 'RAID5' -NodeCount 4 } | Should -Throw
            }
        }
    }
}
