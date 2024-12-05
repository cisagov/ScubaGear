$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-Credentials" {
        BeforeAll {
            # Import mock data
            . ../RiskyPermissionsSnippets/MockData.ps1

            $MockKeyCredentials = $MockApplications[0].KeyCredentials
            $MockPasswordCredentials = $MockServicePrincipals[3].PasswordCredentials
        }
    }
}