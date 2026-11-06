BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Connection.psm1') -Function 'Disconnect-SCuBATenant' -Force
}

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            function Disconnect-ScubaGraph {
                [CmdletBinding()]
                param()
                throw 'this will be mocked'
            }
            Mock -ModuleName Connection Disconnect-ScubaGraph {}
            # EXO now uses REST API - no ExchangeOnline module disconnect needed
            # SharePoint uses REST API - no SPO module disconnect needed
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            Disconnect-SCuBATenant -ErrorAction SilentlyContinue
            Should -Invoke -ModuleName Connection -CommandName Disconnect-ScubaGraph -Times 1 -Exactly
        }
        It 'Disconnects with verbose cleanup options' {
            Disconnect-SCuBATenant -ErrorAction SilentlyContinue -Verbose
            Should -Invoke -ModuleName Connection -CommandName Disconnect-ScubaGraph -Times 1 -Exactly
        }
        It 'Disconnects from all products' {
            {Disconnect-SCuBATenant} | Should -Not -Throw
            Should -Invoke -ModuleName Connection -CommandName Disconnect-ScubaGraph -Times 1 -Exactly
        }
        It 'reports a thrown disconnect error without reporting success' {
            Mock Disconnect-ScubaGraph { throw 'Disconnect failed' }
            Mock Write-Warning {}
            Mock Write-Information {}

            Disconnect-SCuBATenant

            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -like '*Could not disconnect from tenant*Disconnect failed*'
            }
            Should -Invoke Write-Information -Times 0 -Exactly -ParameterFilter {
                $MessageData -eq 'Disconnect Completed!'
            }
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}
