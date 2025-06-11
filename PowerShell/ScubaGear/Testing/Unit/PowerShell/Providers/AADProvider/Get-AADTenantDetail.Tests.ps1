$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-AADTenantDetail' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        Mock Invoke-GraphDirectly {
            return [pscustomobject]@{
                DisplayName = "DisplayName";
                Name = "DomainName";
                Id = "TenantId";
            }
        } -ParameterFilter { $commandlet -eq "Get-MgBetaOrganization" -or $Uri -match "/organization" } -ModuleName ExportAADProvider

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
            $Json = Get-AADTenantDetail -M365Environment Commercial
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}