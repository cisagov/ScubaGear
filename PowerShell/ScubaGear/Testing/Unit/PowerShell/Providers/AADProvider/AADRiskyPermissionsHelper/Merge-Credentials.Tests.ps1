$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Merge-Credentials" {
        BeforeAll {
            # Import mock data
            . ../RiskyPermissionsSnippets/MockData.ps1

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockApplicationCredentials')]
            $MockApplicationCredentials = $MockApplications[0].KeyCredentials
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockSPCredentials')]
            $MockSPCredentials = $MockServicePrincipals[0].KeyCredentials
        }

        It "merges application/service principal credentials together if both are valid" {
            $Output = Merge-Credentials -ApplicationAccessKeys $MockApplicationCredentials -ServicePrincipalAccessKeys $MockSPCredentials
            $Output | Should -HaveCount 3
        }

        It "returns only application credentials if service principal credentials are null" {
            $Output = Merge-Credentials -ApplicationAccessKeys $MockApplicationCredentials -ServicePrincipalAccessKeys $null
            $Output | Should -HaveCount 2
        }

        It "returns only service principal credentials if application credentials are null" {
            $Output = Merge-Credentials -ApplicationAccessKeys $null -ServicePrincipalAccessKeys $MockSPCredentials
            $Output | Should -HaveCount 1
        }

        It "returns null if neither credentials are valid" {
            $Output = Merge-Credentials -ApplicationAccessKeys $null -ServicePrincipalAccessKeys $null
            $Output | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}