$ModulesPath = "../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ApplicationsWithRiskyPermissions" {
        BeforeAll {
            $PermissionsPath = (Join-Path -Path $PSScriptRoot -ChildPath "../../../../../Modules/Permissions")
            $PermissionsJson = (
                Get-Content -Path ( `
                    Join-Path -Path $PermissionsPath -ChildPath "RiskyPermissions.json" `
                ) | ConvertFrom-Json
            )
    
            # Import mock data
            . .\RiskyPermissionsSnippets/MockData.ps1
        
            function Get-MgBetaApplication { return $MockApplications }
            function Get-MgBetaApplicationFederatedIdentityCredential { return $MockFederatedCredentials }
        }

        It "returns a list of applications with valid properties" {
            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
            
            # Refer to $MockApplications in ./RiskyPermissionsSnippets,
            # we are comparing the data stored there with what the function returns
            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps | Should -HaveCount 2
            $RiskyApps[0].IsMultiTenantEnabled | Should -Be $true
            $RiskyApps[0].KeyCredentials | Should -HaveCount 2
            $RiskyApps[0].PasswordCredentials | Should -HaveCount 1
            $RiskyApps[0].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[0].RiskyPermissions | Should -HaveCount 2
            $RiskyApps[1].IsMultiTenantEnabled | Should -Be $false
            $RiskyApps[1].KeyCredentials | Should -HaveCount 1
            $RiskyApps[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskyApps[1].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[1].RiskyPermissions | Should -HaveCount 3
        }
    
        it "excludes ResourceAccess objects with property Type='Scope'" {
            # We only care about objects with type="role".
            # Adding a couple objects with type="scope" to verify they're excluded
            $ResourceAccess = $MockApplications[0].RequiredResourceAccess[0].ResourceAccess
            $ResourcesOfTypeScope = @(
                [PSCustomObject]@{
                    Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96" # Mail.Send
                    Type = "Scope"
                }
                [PSCustomObject]@{
                    Id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
                    Type = "Scope"
                }
            )
            $ResourceAccess += $ResourcesOfTypeScope

            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps[0].RiskyPermissions | Should -HaveCount 2
        }
    
        it "correctly formats federated credentials if they exist" {
            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            foreach ($Credential in $RiskyApps[0].FederatedCredentials) {
                # Check for correct properties
                $ExpectedKeys = @("Id", "Name", "Description", "Issuer", "Subject", "Audiences")
                $Credential.PSObject.Properties.Name | Should -Be $ExpectedKeys

                # Check against an invalid property
                $Credential.PSObject.Properties.Name | Should -NotContain "AppId"
            }
        }
    
        it "sets the list of federated credentials to null if no credentials exist" {
            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps[0].FederatedCredentials | Should -BeNullOrEmpty
        }
    
        it "excludes applications without risky permissions" {
            # Reset to some arbitrary Id not included in RiskyPermissions.json mapping
            $MockApplications[1].RequiredResourceAccess[0].ResourceAccess = @(
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000000" 
                    Type = "Role"
                }
            )
            # Reset to empty list
            $MockApplications[1].RequiredResourceAccess[1].ResourceAccess = @()

            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps | Should -HaveCount 1
        }
    }
}