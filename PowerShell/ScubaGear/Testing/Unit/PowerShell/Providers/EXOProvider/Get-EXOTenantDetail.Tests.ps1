$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") -Function Get-EXOTenantDetail -Force

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
            function Test-SCuBAValidJson {
                param (
                    [string]
                    $Json
                )
                $ValidJson = $true
                try {
                    ConvertFrom-Json $Json -ErrorAction Stop | Out-Null
                }
                catch {
                    $ValidJson = $false;
                }
                $ValidJson
            }
        }
        It "When called with -M365Environment 'commercial', returns valid JSON" {
            $Json = Get-EXOTenantDetail -M365Environment "commercial"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcc', returns valid JSON" {
            $Json = Get-EXOTenantDetail -M365Environment "gcc"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcchigh', returns valid JSON" {
            $Json = Get-EXOTenantDetail -M365Environment "gcchigh"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'dod', returns valid JSON" {
            $Json = Get-EXOTenantDetail -M365Environment "dod"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
    Remove-Module ExchangeOnlineManagement -Force -ErrorAction SilentlyContinue
}