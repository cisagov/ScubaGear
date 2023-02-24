Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportEXOProvider.psm1 -Force

InModuleScope ExportEXOProvider {
    Describe "Get-EXOTenantDetail" {
        BeforeAll {
            # empty stub required for mocked cmdlets called directly in the provider
            function Get-OrganizationConfig {}

            Mock -ModuleName ExportEXOProvider Get-OrganizationConfig -MockWith {
                return [pscustomobject]@{
                    Name = "name";
                    DisplayName = "DisplayName";
                }
            }
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{token_endpoint: "this/is/the/token/url"}'
                }
            }
        }
        It "when called with -M365Environment 'gcc' returns valid JSON" {
            $Json = Get-EXOTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
    Remove-Module ExchangeOnlineManagement -Force -ErrorAction SilentlyContinue
}