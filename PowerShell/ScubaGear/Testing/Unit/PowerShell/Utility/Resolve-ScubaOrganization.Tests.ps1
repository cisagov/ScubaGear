[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Resolve-ScubaOrganization caches on the shared MSAL session singleton.')]
param()
$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Resolve-ScubaOrganization' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Resolve-ScubaOrganization' {
        BeforeAll {
            $script:SavedSession = $Global:ScubaGearState.Session
        }

        BeforeEach {
            $Global:ScubaGearState.Session = @{ M365Environment = 'commercial' }
            Mock Invoke-GraphDirectly {
                return [pscustomobject]@{
                    Value = @(
                        [pscustomobject]@{
                            Id              = '00000000-0000-0000-0000-000000000000'
                            DisplayName     = 'Contoso'
                            VerifiedDomains = @([pscustomobject]@{ IsInitial = $true; Name = 'contoso.onmicrosoft.com' })
                        }
                    )
                }
            } -ParameterFilter { $Commandlet -eq 'Get-MgBetaOrganization' }
        }

        AfterAll {
            $Global:ScubaGearState.Session = $script:SavedSession
        }

        It 'calls Microsoft Graph once and returns the cached record on later calls' {
            $First = Resolve-ScubaOrganization -M365Environment 'commercial'
            $Second = Resolve-ScubaOrganization -M365Environment 'commercial'

            Should -Invoke Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter { $Commandlet -eq 'Get-MgBetaOrganization' }
            $First.Id | Should -Be '00000000-0000-0000-0000-000000000000'
            $Second.Id | Should -Be '00000000-0000-0000-0000-000000000000'
            $Global:ScubaGearState.Session.Organization | Should -Not -BeNullOrEmpty
        }

        It 'returns the record as an array, matching the Graph response shape' {
            $Organization = Resolve-ScubaOrganization -M365Environment 'commercial'
            $Cached = Resolve-ScubaOrganization -M365Environment 'commercial'

            ,$Organization | Should -BeOfType [object[]]
            ,$Cached | Should -BeOfType [object[]]
            $Organization | Should -HaveCount 1
        }

        It 'fetches again after the session is replaced by a new sign-in' {
            $null = Resolve-ScubaOrganization -M365Environment 'commercial'
            $Global:ScubaGearState.Session = @{ M365Environment = 'commercial' }
            $null = Resolve-ScubaOrganization -M365Environment 'commercial'

            Should -Invoke Invoke-GraphDirectly -Times 2 -Exactly -ParameterFilter { $Commandlet -eq 'Get-MgBetaOrganization' }
        }

        It 'does not cache when there is no Graph session' {
            $Global:ScubaGearState.Session = $null
            $null = Resolve-ScubaOrganization -M365Environment 'commercial'
            $null = Resolve-ScubaOrganization -M365Environment 'commercial'

            Should -Invoke Invoke-GraphDirectly -Times 2 -Exactly -ParameterFilter { $Commandlet -eq 'Get-MgBetaOrganization' }
        }

        It 'does not cache an empty response' {
            Mock Invoke-GraphDirectly { return [pscustomobject]@{ Value = $null } } -ParameterFilter { $Commandlet -eq 'Get-MgBetaOrganization' }

            Resolve-ScubaOrganization -M365Environment 'commercial' | Should -BeNullOrEmpty
            $Global:ScubaGearState.Session.Organization | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
