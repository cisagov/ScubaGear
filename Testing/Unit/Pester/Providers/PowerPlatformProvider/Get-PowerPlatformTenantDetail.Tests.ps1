$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportPowerPlatformProvider.psm1") -Function 'Get-PowerPlatformTenantDetail' -Force

InModuleScope ExportPowerPlatformProvider {
    Describe -Tag 'PowerPlatformProvider' -Name "Get-PowerPlatformTenantDetail" {
        BeforeAll {
            # empty stub required for mocked cmdlets called directly in the provider
            function Get-TenantDetailsFromGraph {}
            Mock -ModuleName ExportPowerPlatformProvider Get-TenantDetailsFromGraph -MockWith {
                return [pscustomobject]@{
                    Domains = @(
                        @{
                            Name = "example.onmicrosoft.com";
                            initial = $true;
                        },
                        @{
                            Name = "contoso.onmicrosoft.com";
                            initial = $false;
                        }
                    );
                    DisplayName = "DisplayName";
                    TenantId = "TenantId";
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
            $Json = Get-PowerPlatformTenantDetail -M365Environment "commercial"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcc', returns valid JSON" {
            $Json = Get-PowerPlatformTenantDetail -M365Environment "gcc"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcchigh', returns valid JSON" {
            $Json = Get-PowerPlatformTenantDetail -M365Environment "gcchigh"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'dod', returns valid JSON" {
            $Json = Get-PowerPlatformTenantDetail -M365Environment "dod"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportPowerPlatformProvider -Force -ErrorAction SilentlyContinue
    Remove-Module Microsoft.PowerApps.Administration.PowerShell -Force -ErrorAction SilentlyContinue
}