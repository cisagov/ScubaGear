[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Force
}

# The config app and analyzer make Graph calls from worker runspaces. A call to a PowerShell class method from a
# worker waits forever when the runspace that defined the class is idle at the console prompt, so the sign-in path reads
# these two values from the shared session state instead of calling the ScubaConfig class.
InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Sign-in defaults held in the shared state' {
        AfterAll {
            # Clearing the cache makes the next call fill it again from the class.
            $Global:ScubaGearState.ClientIds = $null
            $Global:ScubaGearState.SupportedEnvironments = $null
        }

        Context 'Get-ScubaGearClientIdTable' {
            It 'returns the table already in the shared state' {
                $Global:ScubaGearState.ClientIds = @{ aad = 'cached-aad-client' }
                (Get-ScubaGearClientIdTable).aad | Should -Be 'cached-aad-client'
            }

            It 'fills the shared state from the ScubaConfig class when it is empty' {
                $Global:ScubaGearState.ClientIds = $null
                $Table = Get-ScubaGearClientIdTable
                $Table.aad | Should -Match '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$'
                $Global:ScubaGearState.ClientIds.aad | Should -Be $Table.aad
            }
        }

        Context 'Get-ScubaGearSupportedEnvironment' {
            It 'returns the list already in the shared state' {
                $Global:ScubaGearState.SupportedEnvironments = @('cached-environment')
                Get-ScubaGearSupportedEnvironment | Should -Be 'cached-environment'
            }

            It 'fills the shared state from the ScubaConfig class when it is empty' {
                $Global:ScubaGearState.SupportedEnvironments = $null
                $Environments = @(Get-ScubaGearSupportedEnvironment)
                $Environments | Should -Contain 'commercial'
                $Environments | Should -Contain 'dod'
                @($Global:ScubaGearState.SupportedEnvironments).Count | Should -Be $Environments.Count
            }

            It 'is what Get-MsalAccessToken validates M365Environment against' {
                $Global:ScubaGearState.SupportedEnvironments = @('only-this-one')
                { Get-MsalAccessToken -Scope 'x' -ClientId 'y' -Tenant 'z' -M365Environment 'commercial' } |
                    Should -Throw "*Cannot validate argument on parameter 'M365Environment'*"
            }

            It 'is what Connect-GraphHelper validates M365Environment against' {
                $Global:ScubaGearState.SupportedEnvironments = @('only-this-one')
                { Connect-GraphHelper -M365Environment 'commercial' } |
                    Should -Throw "*Cannot validate argument on parameter 'M365Environment'*"
            }
        }
    }
}
