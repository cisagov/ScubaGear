$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportTeamsProvider.psm1") -Function Get-TeamsTenantDetail -Force

InModuleScope ExportTeamsProvider {
    Describe -Tag 'TeamsProvider' -Name "Get-TeamsTenantDetail" {
        BeforeAll {
            # empty stub required for mocked cmdlets called directly in the provider
            function Get-CsTenant {}
            Mock -ModuleName ExportTeamsProvider Get-CsTenant -MockWith {
                return [pscustomobject]@{
                    VerifiedDomains = @(
                        @{
                            Name = "example.onmicrosoft.com";
                            Status = "Enabled";
                        },
                        @{
                            Name = "contoso.onmicrosoft.com";
                            Status = "Disabled";
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
            $Json = Get-TeamsTenantDetail -M365Environment "commercial"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcc', returns valid JSON" {
            $Json = Get-TeamsTenantDetail -M365Environment "gcc"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcchigh', returns valid JSON" {
            $Json = Get-TeamsTenantDetail -M365Environment "gcchigh"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'dod', returns valid JSON" {
            $Json = Get-TeamsTenantDetail -M365Environment "dod"
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportTeamsProvider -Force -ErrorAction SilentlyContinue
}