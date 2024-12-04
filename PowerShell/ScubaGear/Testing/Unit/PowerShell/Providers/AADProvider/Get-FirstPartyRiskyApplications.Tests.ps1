$ModulesPath = "../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-FirstPartyRiskyApplications" {
        BeforeAll {
            # Import mock data
            . .\RiskyPermissionsSnippets/MockData.ps1
        
            function Get-ApplicationsWithRiskyPermissions { $MockApplications }
            function Get-ServicePrincipalsWithRiskyPermissions { $MockServicePrincipals }
        }

        It "returns a list of first-party risky applications with valid properties" {

        }

        It "matches service principals with applications that have the same AppId" {

        }

        It "sets an application permission's admin consent property to true" {
            
        }

        It "correctly formats the object with merged properties from both applications and service principals" {
            # Object IDs are merged into a single object, but as separate properties
            # KeyCredentials/PasswordCredentials/FederatedCredentials are merged into one list
        }
        It "keeps applications in the merged dataset that don't have a matching service principal object" {
            
        }
    }
}