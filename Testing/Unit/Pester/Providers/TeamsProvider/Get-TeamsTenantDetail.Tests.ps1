Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1 -Force

InModuleScope ExportTeamsProvider {
    Describe "Get-TeamsTenantDetail" {
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
        }
        It "return JSON" {
            $Json = Get-TeamsTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportTeamsProvider -Force -ErrorAction SilentlyContinue
}