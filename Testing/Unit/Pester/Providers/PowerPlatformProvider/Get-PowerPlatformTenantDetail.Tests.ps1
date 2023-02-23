Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportPowerPlatformProvider.psm1

InModuleScope ExportPowerPlatformProvider {
    Describe "Get-PowerPlatformTenantDetail" {

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
        }

        It "when called with -M365Environment 'gcc' returns valid JSON" {
            $json = Get-PowerPlatformTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportPowerPlatformProvider -Force -ErrorAction SilentlyContinue
    Remove-Module Microsoft.PowerApps.Administration.PowerShell -Force -ErrorAction SilentlyContinue
}