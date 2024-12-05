$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Merge-Credentials" {
        BeforeAll {
            # Import mock data
            . ../RiskyPermissionsSnippets/MockData.ps1

            $MockApplicationCredentials = $MockApplications[0].KeyCredentials
            $MockSPCredentials = $MockServicePrincipals[0].KeyCredentials
        }
        
        It "merges application/service principal credentials together if both are valid" {
            $Output = Merge-Credentials -ApplicationCredentials $MockApplicationCredentials -ServicePrincipalCredentials $MockSPCredentials
            $Output | Should -HaveCount 3
        }
    
        It "returns only application credentials if service principal credentials are null" {
            $Output = Merge-Credentials -ApplicationCredentials $MockApplicationCredentials -ServicePrincipalCredentials $null
            $Output | Should -HaveCount 2
        }
    
        It "returns only service principal credentials if application credentials are null" {
            $Output = Merge-Credentials -ApplicationCredentials $null -ServicePrincipalCredentials $MockSPCredentials
            $Output | Should -HaveCount 1
        }
    
        It "returns null if neither credentials are valid" {
            $Output = Merge-Credentials -ApplicationCredentials $null -ServicePrincipalCredentials $null
            $Output | Should -BeNullOrEmpty
        }
    }
}