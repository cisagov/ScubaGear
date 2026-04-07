$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-Credentials" {
        BeforeAll {
            # Import mock data
            $MockApplications = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplications.json") | ConvertFrom-Json
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockFederatedCredentials')]
            $MockFederatedCredentials = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockFederatedCredentials.json") | ConvertFrom-Json

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockKeyCredentials')]
            $MockKeyCredentials = $MockApplications[0].KeyCredentials
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockPasswordCredentials')]
            $MockPasswordCredentials = $MockServicePrincipals[3].PasswordCredentials
        }

        Context "Key/password credentials (non-federated)" {
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

        Context "Federated credentials (specifies different required keys with -IsFederated parameter)" {
            It "returns the correct number of federated credential objects" {
                $Output = Format-Credentials -AccessKeys $MockFederatedCredentials -IsFromApplication $true -IsFederated
                $Output | Should -HaveCount 2
                foreach ($Obj in $Output) {
                    $Obj.IsFromApplication | Should -Be $true
                }
            }

            It "formats federated credential output with correct properties" {
                $ExpectedKeys = @("Id", "Name", "Description", "Issuer", "Subject", "Audiences", "IsFromApplication")
                $Output = Format-Credentials -AccessKeys $MockFederatedCredentials -IsFromApplication $true -IsFederated
                $Output | Should -HaveCount 2
                foreach ($Obj in $Output) {
                    $Obj.PSObject.Properties.Name | Should -Be $ExpectedKeys
                }
            }

            It "correctly sets IsFromApplication to false for SP federated credentials" {
                $Output = Format-Credentials -AccessKeys $MockFederatedCredentials -IsFromApplication $false -IsFederated
                $Output | Should -HaveCount 2
                foreach ($Obj in $Output) {
                    $Obj.IsFromApplication | Should -Be $false
                }
            }

            It "returns null if federated credentials equal null" {
                $Output = Format-Credentials -AccessKeys $null -IsFromApplication $true -IsFederated
                $Output | Should -BeNullOrEmpty
            }

            It "returns null if federated credential count is 0" {
                $Output = Format-Credentials -AccessKeys @() -IsFromApplication $true -IsFederated
                $Output | Should -BeNullOrEmpty
            }

            It "excludes federated credentials missing required keys" {
                $InvalidFederatedCredential = @(
                    [PSCustomObject]@{
                        KeyId       = "00000000-0000-0000-0000-000000000003"
                        DisplayName = "Invalid federated credential" # missing Id, Name, Issuer, Subject, Audiences
                    }
                )
                $Combined = @($MockFederatedCredentials) + $InvalidFederatedCredential
                $Output = Format-Credentials -AccessKeys $Combined -IsFromApplication $true -IsFederated
                $Output | Should -HaveCount 2
            }

            It "does not include non-federated properties (StartDateTime/EndDateTime) in federated output" {
                $Output = Format-Credentials -AccessKeys $MockFederatedCredentials -IsFromApplication $true -IsFederated
                foreach ($Obj in $Output) {
                    $Obj.PSObject.Properties.Name | Should -Not -Contain "StartDateTime"
                    $Obj.PSObject.Properties.Name | Should -Not -Contain "EndDateTime"
                    $Obj.PSObject.Properties.Name | Should -Not -Contain "KeyId"
                }
            }
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}