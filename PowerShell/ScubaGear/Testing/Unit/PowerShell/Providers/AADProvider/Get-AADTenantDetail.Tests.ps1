$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-AADTenantDetail' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        Mock Resolve-ScubaOrganization {
            return ,@(
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
        } -ModuleName ExportAADProvider

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

        It "reads the organization through the session cache instead of calling Graph directly" {
            Mock Invoke-GraphDirectly {} -ModuleName ExportAADProvider
            $null = Get-AADTenantDetail -M365Environment Commercial

            Should -Invoke Resolve-ScubaOrganization -ModuleName ExportAADProvider -Times 1 -Exactly
            Should -Invoke Invoke-GraphDirectly -ModuleName ExportAADProvider -Times 0 -Exactly
        }

        It "keeps AADAdditionalData as an array of organization records" {
            $Json = Get-AADTenantDetail -M365Environment Commercial
            $Json | Should -Match '"AADAdditionalData":\s*\['
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}