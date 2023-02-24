Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportAADProvider.psm1 -Function "Get-PrivilegedUser" -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-MgOrganization {}
        Mock -ModuleName ExportAADProvider Get-MgOrganization -MockWith {
            return [pscustomobject]@{
                DisplayName = "DisplayName";
                Name = "DomainName";
                Id = "TenantId";
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
    Describe -Tag 'AADProvider' -Name "Get-PrivilegedUser" {
        It "Returns valid JSON" {
            $Json = Get-PrivilegedUser
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}