$ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules'
Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Orchestrator.psm1') -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        Context 'When LogIn is true' {
            BeforeEach {
                # Fresh config & mock per test to avoid state leakage
                $script:ScubaConfig = [PSCustomObject]@{
                    ProductNames    = @('aad')  # default, overridden in tests
                    LogIn           = $true
                    M365Environment = 'commercial'
                }
                $script:BoundParameters = @{}
                function Connect-Tenant { throw 'this will be mocked' }
                Mock -ModuleName Orchestrator Connect-Tenant { @() }
            }

            It 'connects to aad (single product)' {
                $FailedAuthList = Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters
                Should -Invoke -CommandName Connect-Tenant -Times 1 -Exactly
                $FailedAuthList | Should -BeNullOrEmpty
            }
            It 'connects to defender' {
                $ScubaConfig.ProductNames = @('defender')
                $FailedAuthList = Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters
                Should -Invoke -CommandName Connect-Tenant -Times 1 -Exactly
                $FailedAuthList | Should -BeNullOrEmpty
            }
            It 'connects to all products in one call' {
                $ScubaConfig.ProductNames = @('aad','defender','exo','powerplatform','sharepoint','teams')
                $FailedAuthList = Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters
                # Still only one Connect-Tenant invocation expected (array passed)
                Should -Invoke -CommandName Connect-Tenant -Times 1 -Exactly
                $FailedAuthList | Should -BeNullOrEmpty
            }
            It 'passes service principal parameters when provided' {
                $ScubaConfig.ProductNames = @('aad')
                $BoundParameters = @{ AppID = 'a'; CertificateThumbprint = 'b'; Organization = 'c' }
                $FailedAuthList = Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters
                Should -Invoke -CommandName Connect-Tenant -Times 1 -Exactly
                $FailedAuthList | Should -BeNullOrEmpty
            }
        }

        Context 'When LogIn is false' {
            BeforeEach {
                $script:ScubaConfig = [PSCustomObject]@{
                    ProductNames    = @('aad')
                    LogIn           = $false
                    M365Environment = 'commercial'
                }
                $script:BoundParameters = @{}
                function Connect-Tenant { throw 'this will be mocked' }
                Mock -ModuleName Orchestrator Connect-Tenant { @() }
            }
            It 'does not attempt authentication' {
                Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters | Should -BeNullOrEmpty
                Should -Invoke -CommandName Connect-Tenant -Times 0 -Exactly
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
