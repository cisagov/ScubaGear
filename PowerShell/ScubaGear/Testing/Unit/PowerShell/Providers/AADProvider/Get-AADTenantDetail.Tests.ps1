$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-AADTenantDetail' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        Mock Invoke-GraphDirectly {
            return [pscustomobject]@{
                Value = @(
                    [pscustomobject]@{
                        DisplayName = "DisplayName";
                        Id = "TenantId";
                        MobileDeviceManagementAuthority = $null;
                        VerifiedDomains = @(
                            [pscustomobject]@{
                                IsInitial = $true;
                                Name = "DomainName";
                            }
                        )
                    }
                )
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
        It "returns tenant details from a Graph response with null properties" {
            $Json = Get-AADTenantDetail -M365Environment Commercial
            $TenantDetails = $Json | ConvertFrom-Json

            $TenantDetails.DisplayName | Should -Be "DisplayName"
            $TenantDetails.DomainName | Should -Be "DomainName"
            $TenantDetails.TenantId | Should -Be "TenantId"
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}