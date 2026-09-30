$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-ProviderList' -Force

InModuleScope Orchestrator {
Describe -Tag 'Orchestrator' -Name 'Invoke-ProviderList' {
    BeforeAll {
    function Set-Utf8NoBom {}
    Mock -ModuleName Orchestrator Set-Utf8NoBom {}
        function Export-AADProvider {}
        Mock -ModuleName Orchestrator Export-AADProvider {}
        function Export-EXOProvider {}
        Mock -ModuleName Orchestrator Export-EXOProvider {}
        function Export-SecuritySuiteProvider {}
        Mock -ModuleName Orchestrator Export-SecuritySuiteProvider {}
        function Export-PowerPlatformProvider {}
        Mock -ModuleName Orchestrator Export-PowerPlatformProvider {}
        function Export-SharePointProvider {}
        Mock -ModuleName Orchestrator Export-SharePointProvider {}
        function Export-TeamsProvider {}
        Mock -ModuleName Orchestrator Export-TeamsProvider {}
        # Declared with the real signature so Should -Invoke -ParameterFilter can bind the arguments.
        function Export-PowerBIProvider {
            param($CertificateBasedAuth, $AccessToken, $BaseUrl, $LicenseFound)
            # Pester replaces this body, so it never runs; the assignment just keeps PSSA from
            # flagging the parameters as unused.
            $null = $CertificateBasedAuth, $AccessToken, $BaseUrl, $LicenseFound
        }
        Mock -ModuleName Orchestrator Export-PowerBIProvider {}
        function Get-ServicePrincipalParams {}
        Mock -ModuleName Orchestrator Get-ServicePrincipalParams {
            @{ CertThumbprintParams = @{
                CertificateThumbprint = "0000000000000000000000000000000000000000"
                AppID                 = "00000000-0000-0000-0000-000000000000"
                Organization          = "example.onmicrosoft.com"
            } }
        }
        function Get-FileEncoding {}
        Mock -ModuleName Orchestrator Get-FileEncoding {}

        Mock -CommandName Write-Progress {}
        Mock -CommandName Join-Path {"."}
        Mock -CommandName Set-Content {}
        Mock -CommandName Get-TimeZone {}
        Mock -CommandName Set-Utf8NoBom {}
        Mock -CommandName Write-Debug {}
    }
    Context 'When running the providers on commercial tenants' {
        BeforeAll {
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfig')]
              $ScubaConfig = [PSCustomObject]@{
                 ProductNames = @('aad')
                 OutProviderFileName = "ProviderSettingsExport"
                 M365Environment = "commercial"
                 OutRegoFileName = "RegoOutput"
                 OutReportName = "BaselineReports"
                 OPAPath = "."
                 LogIn = $false
                 PreferredDnsResolvers = @()
                 SkipDoH = $false
              }
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TenantDetails')]
              $TenantDetails = '{"DisplayName": "displayName"}'
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleVersion')]
              $ModuleVersion = '1.0'
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
              $OutFolderPath = "./output"
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Guid')]
              $Guid = "00000000-0000-0000-0000-000000000000"
                            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ConnectionResult')]
                            $ConnectionResult = @{
                                    EXOAccessToken = "mock-access-token"
                                    EXOApiEndpoint = "https://outlook.office365.com/adminapi/beta/mock-tenant/InvokeCommand"
                                    PBIAccessToken = "mock-pbi-access-token"
                                    PBIBaseUrl = "https://api.powerbi.com"
                                    PBILicenseFound = $true
                            }
        }
        It 'With -ProductNames "aad", should not throw' {
              $ScubaConfig.ProductNames = @("aad")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "securitysuite", should not throw' {
              $ScubaConfig.ProductNames = @("securitysuite")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "exo", should not throw' {
              $ScubaConfig.ProductNames = @("exo")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "powerplatform", should not throw' {
              $ScubaConfig.ProductNames = @("powerplatform")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "sharepoint", should not throw' {
              $ScubaConfig.ProductNames = @("sharepoint")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "teams", should not throw' {
              $ScubaConfig.ProductNames = @("teams")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With -ProductNames "powerbi", should not throw' {
              $ScubaConfig.ProductNames = @("powerbi")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        It 'With all products, should not throw' {
              $ScubaConfig.ProductNames = @("aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams", "powerbi")
                        { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult } | Should -Not -Throw
        }
        # The Power BI provider picks which 403/401 remediation message to show based on
        # CertificateBasedAuth, so the orchestrator must only set it for service principal auth.
        It 'With -ProductNames "powerbi" and interactive auth, does not pass CertificateBasedAuth' {
              $ScubaConfig.ProductNames = @("powerbi")
              $ScubaConfig | Add-Member -NotePropertyName AppID -NotePropertyValue $null -Force
              Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
              Should -Invoke -ModuleName Orchestrator -CommandName Export-PowerBIProvider -Times 1 -Exactly -ParameterFilter {
                  -not $CertificateBasedAuth
              }
        }
        It 'With -ProductNames "powerbi" and service principal auth, passes CertificateBasedAuth' {
              $ScubaConfig.ProductNames = @("powerbi")
              $ScubaConfig | Add-Member -NotePropertyName AppID -NotePropertyValue "00000000-0000-0000-0000-000000000000" -Force
              Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
              Should -Invoke -ModuleName Orchestrator -CommandName Export-PowerBIProvider -Times 1 -Exactly -ParameterFilter {
                  $CertificateBasedAuth -eq $true
              }
        }
        It 'With -ProductNames "powerbi", forwards the connection token, base URL, and license state' {
              $ScubaConfig.ProductNames = @("powerbi")
              $ScubaConfig | Add-Member -NotePropertyName AppID -NotePropertyValue $null -Force
              Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
              Should -Invoke -ModuleName Orchestrator -CommandName Export-PowerBIProvider -Times 1 -Exactly -ParameterFilter {
                  $AccessToken -eq "mock-pbi-access-token" -and
                  $BaseUrl -eq "https://api.powerbi.com" -and
                  $LicenseFound -eq $true
              }
        }
        # A Power BI 403 now surfaces as a thrown exception from the provider. Invoke-ProviderList
        # must absorb it and continue so the remaining products still produce a report.
        It 'With a Power BI provider failure, does not throw and still runs the other products' {
              Mock -ModuleName Orchestrator Export-PowerBIProvider { throw "The remote server returned an error: (403) Forbidden." }
              $ScubaConfig.ProductNames = @("powerbi", "aad")
              { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult -WarningAction SilentlyContinue } | Should -Not -Throw
              Should -Invoke -ModuleName Orchestrator -CommandName Export-AADProvider -Times 1 -Exactly
        }
    }
}
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
