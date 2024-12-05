$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-Credentials" {
        BeforeAll {
            # Import mock data
            . ../RiskyPermissionsSnippets/MockData.ps1

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockKeyCredentials')]
            $MockKeyCredentials = $MockApplications[0].KeyCredentials
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockPasswordCredentials')]
            $MockPasswordCredentials = $MockServicePrincipals[3].PasswordCredentials
        }

        It "returns the correct number of objects (key credential variant)" {
            $Output = Format-Credentials -AccessKeys $MockKeyCredentials -IsFromApplication $true
            $Output | Should -HaveCount 2
            foreach ($Obj in $Output) {
                $Obj.IsFromApplication | Should -Be $true
            }
        }

        It "returns the correct number of objects (password credential variant)" {
            $Output = Format-Credentials -AccessKeys $MockPasswordCredentials -IsFromApplication $false
            $Output | Should -HaveCount 2
            foreach ($Obj in $Output) {
                $Obj.IsFromApplication | Should -Be $false
            }
        }

        It "formats the return output correctly" {
            # Test with true/false values for IsFromApplication
            $ExpectedKeys = @("KeyId", "DisplayName", "StartDateTime", "EndDateTime", "IsFromApplication")
            $Output = Format-Credentials -AccessKeys $MockKeyCredentials -IsFromApplication $true
            $Output | Should -HaveCount 2
            foreach ($Obj in $Output) {
                $Obj.IsFromApplication | Should -Be $true
                $Obj.PSObject.Properties.Name | Should -Be $ExpectedKeys
            }

            $Output = Format-Credentials -AccessKeys $MockKeyCredentials -IsFromApplication $false
            $Output | Should -HaveCount 2
            foreach ($Obj in $Output) {
                $Obj.IsFromApplication | Should -Be $false
                $Obj.PSObject.Properties.Name | Should -Be $ExpectedKeys
            }
        }

        It "returns null if credentials equal null" {
            $Output = Format-Credentials -AccessKeys $null -IsFromApplication $true
            $Output | Should -BeNullOrEmpty
        }

        It "returns null if the credential count is 0" {
            $Output = Format-Credentials -AccessKeys @() -IsFromApplication $true
            $Output | Should -BeNullOrEmpty
        }

        It "excludes credentials that don't have the correct keys" {
            $InvalidKeyCredential = @(
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000003"
                    Name = "Test key credential 3"
                    DateTime = "\/Date(1733343742000)\/" # valid credential
                }
            )
            $MockKeyCredentials += $InvalidKeyCredential
            $Output = Format-Credentials -AccessKeys $MockKeyCredentials -IsFromApplication $true
            $Output | Should -HaveCount 2
        }
    }
}