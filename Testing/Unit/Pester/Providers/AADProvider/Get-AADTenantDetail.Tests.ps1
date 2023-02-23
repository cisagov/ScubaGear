Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportAADProvider.psm1

InModuleScope ExportAADProvider {
    BeforeAll {
        # empty stub required for mocked cmdlets called directly in the provider
        function Get-MgOrganization {}
        Mock -ModuleName ExportAADProvider Get-MgOrganization -MockWith {
            return [pscustomobject]@{
                DisplayName = "DisplayName";
                Name = "DomainName";
                Id = "TenantId";
            }
        }
    }
    Describe "Get-AADTenantDetail" {
        It "when called returns valid JSON" {
            $Json = Get-AADTenantDetail
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
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}