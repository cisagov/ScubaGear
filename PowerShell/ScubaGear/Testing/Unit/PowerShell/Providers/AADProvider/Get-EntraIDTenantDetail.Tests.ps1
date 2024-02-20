$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportENTRAIDProvider.psm1") -Function 'Get-ENTRAIDTenantDetail' -Force

InModuleScope ExportENTRAIDProvider {
    BeforeAll {
        function Get-MgBetaOrganization {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaOrganization -MockWith {
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
    Describe -Tag 'ENTRAIDProvider' -Name "Get-ENTRAIDTenantDetail" {
        It "Returns valid JSON" {
            $Json = Get-ENTRAIDTenantDetail
            $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module ExportENTRAIDProvider -Force -ErrorAction SilentlyContinue
}