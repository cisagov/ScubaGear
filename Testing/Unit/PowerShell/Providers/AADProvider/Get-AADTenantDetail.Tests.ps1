$ProviderPath = '../../../../../PowerShell/ScubaGear/Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-AADTenantDetail' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-MgBetaOrganization {}
        Mock -ModuleName ExportAADProvider Get-MgBetaOrganization -MockWith {
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
    Describe -Tag 'AADProvider' -Name "Get-AADTenantDetail" {
        It "Returns valid JSON" {
            $Json = Get-AADTenantDetail
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}