<#
 # Power BI license detection in Connect-Tenant.
 #
 # The Power BI Admin REST API returns 403/401 unless the caller is licensed and has signed into
 # the Power BI portal, so Connect-Tenant pre-checks licensing and sets PBILicenseFound to avoid
 # triggering a pointless consent prompt.
#>

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Connection/Connection.psm1") -Function 'Connect-Tenant' -Force

InModuleScope Connection {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Permissions/PermissionsHelper.psm1") -Force

    Describe -Tag 'Connection' -Name 'Connect-Tenant Power BI license detection' {
        BeforeAll {
            $script:ServicePrincipalParams = @{
                CertThumbprintParams = @{
                    AppID                 = "00000000-0000-0000-0000-000000000000"
                    CertificateThumbprint = "0000000000000000000000000000000000000000"
                    Organization          = "contoso.onmicrosoft.com"
                }
            }

            # Tenant-level service plans, as /subscribedSkus would report them.
            function New-SubscribedSku {
                param(
                    [string]$PlanName = "POWER_BI_STANDARD",
                    [string]$Status = "Success"
                )
                [pscustomobject]@{
                    Value = [pscustomobject]@{
                        ServicePlans = @(
                            [pscustomobject]@{ ServicePlanName = $PlanName; ProvisioningStatus = $Status }
                        )
                    }
                }
            }

            function New-OrgDetails {
                [pscustomobject]@{
                    Value = [pscustomobject]@{
                        DisplayName     = "DisplayName"
                        Id              = "305102d0-7ccc-4007-83bb-ac1f44f8d620"
                        VerifiedDomains = @(
                            @{ isInitial = $false; Name = "example.onmicrosoft.com" },
                            @{ isInitial = $true; Name = "contoso.onmicrosoft.com" }
                        )
                    }
                }
            }

            # Per-user licenses, as /v1.0/me/licenseDetails would report them.
            function New-UserLicense {
                param(
                    [string]$PlanName = "POWER_BI_STANDARD",
                    [string]$Status = "Success"
                )
                [pscustomobject]@{
                    value = @(
                        [pscustomobject]@{
                            servicePlans = @(
                                [pscustomobject]@{ servicePlanName = $PlanName; provisioningStatus = $Status }
                            )
                        }
                    )
                }
            }

            # These stubs mirror the real signatures on purpose. Pester binds mock arguments from
            # the stub's metadata, so a parameterless stub leaves $commandlet (and friends) $null
            # inside the mock body, and omitting [CmdletBinding()] makes -ErrorAction fail to bind.
            function Connect-GraphHelper { throw 'this will be mocked' }

            # The bodies never run (Pester replaces them); the assignments just keep PSSA from
            # flagging the deliberately-declared parameters as unused.
            function Get-MsalAccessToken {
                [CmdletBinding()]
                param($Scope, $CertificateThumbprint, $AppID, $ClientId, $Tenant, $M365Environment)
                $null = $Scope, $CertificateThumbprint, $AppID, $ClientId, $Tenant, $M365Environment
                throw 'this will be mocked'
            }

            function Invoke-GraphDirectly {
                [CmdletBinding()]
                param($commandlet, $M365Environment, $queryParams, $ID, $Body)
                $null = $commandlet, $M365Environment, $queryParams, $ID, $Body
                throw 'this will be mocked'
            }

            function Invoke-MgGraphRequest {
                [CmdletBinding()]
                param($Method, $Uri)
                $null = $Method, $Uri
                throw 'this will be mocked'
            }

            function Get-MgContext { throw 'this will be mocked' }
            function Get-M365EnvironmentByDomain { throw 'this will be mocked' }
        }

        BeforeEach {
            Mock Connect-GraphHelper -MockWith {}
            Mock -CommandName Write-Progress -MockWith {}
            Mock Get-MsalAccessToken -MockWith { return "mock-pbi-access-token" }
            Mock Get-MgContext -MockWith {
                return [pscustomobject]@{ TenantId = "305102d0-7ccc-4007-83bb-ac1f44f8d620" }
            }
            Mock Get-M365EnvironmentByDomain -MockWith { return 'commercial' }

            # Tenant has a Power BI plan, and the running user has one too. Individual tests
            # override whichever half of this they are exercising.
            Mock Invoke-GraphDirectly -MockWith {
                if ($Commandlet -eq 'Get-MgBetaSubscribedSku') { return New-SubscribedSku }
                return New-OrgDetails
            }
            Mock Invoke-MgGraphRequest -MockWith { return New-UserLicense }
        }

        Context 'When the tenant has a Power BI license and the user is licensed' {
            It 'sets PBILicenseFound to true' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                $Result.PBILicenseFound | Should -BeTrue
            }

            It 'acquires a Power BI access token and base URL' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                $Result.PBIAccessToken | Should -Be 'mock-pbi-access-token'
                $Result.PBIBaseUrl | Should -Be 'https://api.powerbi.com'
            }

            It 'leaves PBILicenseReason empty' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                $Result.PBILicenseReason | Should -BeNullOrEmpty
            }

            It 'does not report an auth failure' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                @($Result.ProdAuthFailed).Count | Should -Be 0
            }

            It 'recognizes Fabric plans as a Power BI license' {
                Mock Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaSubscribedSku') { return New-SubscribedSku -PlanName 'FABRIC_FREE' }
                    return New-OrgDetails
                }
                Mock Invoke-MgGraphRequest -MockWith { return New-UserLicense -PlanName 'FABRIC_FREE' }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                $Result.PBILicenseFound | Should -BeTrue
            }

            It 'recognizes premium-per-user plans as a Power BI license' {
                Mock Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaSubscribedSku') { return New-SubscribedSku -PlanName 'PBI_PREMIUM_PER_USER' }
                    return New-OrgDetails
                }
                Mock Invoke-MgGraphRequest -MockWith { return New-UserLicense -PlanName 'PBI_PREMIUM_PER_USER' }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial'
                $Result.PBILicenseFound | Should -BeTrue
            }
        }

        Context 'When the tenant has no Power BI license' {
            BeforeEach {
                Mock Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaSubscribedSku') {
                        return New-SubscribedSku -PlanName 'EXCHANGE_S_STANDARD'
                    }
                    return New-OrgDetails
                }
            }

            It 'sets PBILicenseFound to false' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }

            It 'reports the tenant as the reason' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseReason | Should -Match 'No Power BI or Fabric license found in the tenant'
            }

            # The whole point of the pre-check: never request the Power BI scope without a license,
            # because that triggers a consent/sign-in prompt that cannot succeed.
            It 'does not acquire a Power BI token' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBIAccessToken | Should -BeNullOrEmpty
                Should -Invoke -CommandName Get-MsalAccessToken -Times 0 -Exactly
            }

            It 'does not check the per-user license once the tenant has none' {
                Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue | Out-Null
                Should -Invoke -CommandName Invoke-MgGraphRequest -Times 0 -Exactly
            }

            It 'does not report an auth failure' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                @($Result.ProdAuthFailed).Count | Should -Be 0
            }

            # A plan that exists but never finished provisioning must not count as licensed.
            It 'ignores Power BI plans that are not provisioned successfully' {
                Mock Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaSubscribedSku') {
                        return New-SubscribedSku -PlanName 'POWER_BI_STANDARD' -Status 'Disabled'
                    }
                    return New-OrgDetails
                }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }
        }

        Context 'When the tenant is licensed but the interactive user is not' {
            BeforeEach {
                Mock Invoke-MgGraphRequest -MockWith { return [pscustomobject]@{ value = @() } }
            }

            It 'sets PBILicenseFound to false' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }

            It 'reports the running user as the reason, not the tenant' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseReason | Should -Match 'Current user does not have a Power BI or Fabric license assigned'
                $Result.PBILicenseReason | Should -Not -Match 'found in the tenant'
            }

            It 'does not acquire a Power BI token' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBIAccessToken | Should -BeNullOrEmpty
            }

            It 'ignores user plans that are not provisioned successfully' {
                Mock Invoke-MgGraphRequest -MockWith { return New-UserLicense -Status 'PendingActivation' }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }

            It 'ignores user plans unrelated to Power BI' {
                Mock Invoke-MgGraphRequest -MockWith { return New-UserLicense -PlanName 'EXCHANGE_S_STANDARD' }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }
        }

        Context 'When authenticating as a service principal' {
            # Service principals cannot hold a user license; access is granted through the Power BI
            # tenant setting plus a security group, so the per-user check must be skipped entirely.
            It 'does not perform the per-user license check' {
                Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -ServicePrincipalParams $script:ServicePrincipalParams | Out-Null
                Should -Invoke -CommandName Invoke-MgGraphRequest -Times 0 -Exactly
            }

            It 'sets PBILicenseFound to true when the tenant is licensed' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -ServicePrincipalParams $script:ServicePrincipalParams
                $Result.PBILicenseFound | Should -BeTrue
            }

            It 'still honors the tenant-level license check' {
                Mock Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaSubscribedSku') {
                        return New-SubscribedSku -PlanName 'EXCHANGE_S_STANDARD'
                    }
                    return New-OrgDetails
                }
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -ServicePrincipalParams $script:ServicePrincipalParams -WarningAction SilentlyContinue
                $Result.PBILicenseFound | Should -BeFalse
            }

            It 'acquires the token with the certificate thumbprint' {
                Connect-Tenant -ProductNames @('powerbi') -M365Environment 'commercial' -ServicePrincipalParams $script:ServicePrincipalParams | Out-Null
                Should -Invoke -CommandName Get-MsalAccessToken -ParameterFilter {
                    $CertificateThumbprint -eq '0000000000000000000000000000000000000000'
                }
            }
        }

        Context 'When resolving the Power BI base URL per environment' -ForEach @(
            @{ Environment = 'commercial'; ExpectedUrl = 'https://api.powerbi.com' }
            @{ Environment = 'gcc';        ExpectedUrl = 'https://api.powerbigov.us' }
            @{ Environment = 'gcchigh';    ExpectedUrl = 'https://api.high.powerbigov.us' }
            @{ Environment = 'dod';        ExpectedUrl = 'https://api.mil.powerbigov.us' }
        ) {
            It 'uses <ExpectedUrl> for <Environment>' {
                $Result = Connect-Tenant -ProductNames @('powerbi') -M365Environment $Environment -ServicePrincipalParams $script:ServicePrincipalParams
                $Result.PBIBaseUrl | Should -Be $ExpectedUrl
            }
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
    Remove-Module PermissionsHelper -ErrorAction SilentlyContinue
}
