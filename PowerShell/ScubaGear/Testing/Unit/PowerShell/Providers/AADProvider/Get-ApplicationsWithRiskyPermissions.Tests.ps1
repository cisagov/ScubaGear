$ModulesPath = "../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    BeforeAll {
        $PermissionsPath = (Join-Path -Path $PSScriptRoot -ChildPath "../../../../../Modules/Permissions")
        $PermissionsJson = (
            Get-Content -Path ( `
                Join-Path -Path $PermissionsPath -ChildPath "RiskyPermissions.json" `
            ) | ConvertFrom-Json
        )
    
        $MockApplications = @(
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000001"
                    AppId = "00000000-0000-0000-0000-000000000000"
                    DisplayName = "Test App 1"
                    RequiredResourceAccess = @(
                        "00000003-0000-0000-c000-000000000000",
                        "00000002-0000-0ff1-ce00-000000000000",
                        "00000003-0000-0ff1-ce00-000000000000"
                    )
                    SignInAudience = "AzureADMultipleOrgs"
                    KeyCredentials =  @()
                    PasswordCredentials = @()
                }
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000002"
                    AppId = "00000000-0000-0000-0000-000000000000"
                    DisplayName = "Test App 2"
                    RequiredResourceAccess = @(
                        "00000003-0000-0000-c000-000000000000",
                        "00000002-0000-0ff1-ce00-000000000000",
                        "00000003-0000-0ff1-ce00-000000000000"
                    )
                    SignInAudience = "AzureADMyOrg"
                    KeyCredentials =  @()
                    PasswordCredentials = @()
                }
            )
        function Get-MgBetaApplication { return $MockApplications }
        $MockFederatedCredentials = @(
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000001"
                    Name = "federated credential 1"
                    Description = ""
                    Issuer = "https://token.issuer.domain.com"
                    Subject = "repo:testorg/123:refs/tags/1.0"
                    Audiences = "api://AzureADTokenExchange"
                }
            )
        function Get-MgBetaApplicationFederatedIdentityCredential { return $MockFederatedCredentials }
    }
    
    Describe "Get-ApplicationsWithRiskyPermissions" {
        It "returns a list of applications with correctly mapped risky permissions" {
    
            
            Mock Get-MgBetaApplication {
                $MockApplications
            }
    
            
            Mock Get-MgBetaApplicationFederatedIdentityCredential {
                $MockFederatedCredentials
            }
    
            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            Write-Output $RiskyApps > testforriskyapps.txt
        }
    
        it "checks that '$IsMultiTenantEnabled' is set to $true if the application's SignInAudience = 'AzureADMultipleOrgs'" {
    
        }
    
        it "excludes ResourceAccess objects with property Type='Scope'" {
    
        }
    
        it "correctly formats federated credentials if they exist" {
    
        }
    
        it "sets $FederatedCredentialsResults to $null if no federated credentials exist" {
    
        }
    
        it "excludes applications without risky permissions" {
    
        }
    }
}