# The purpose of this test is to verify that the shared Key Vault functions
# (Get-KeyVaultInfo and Get-KeyVaultSecret) work correctly.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    . $PSScriptRoot/../../utils/workflow/Get-KeyVaultSecret.ps1

    $global:TestKeyVaultInfo = @{
        KeyVault = @{
            URL             = "https://test-keyvault.vault.azure.net/"
            CertificateName = "test-certificate"
        }
    } | ConvertTo-Json

    $global:InvalidKeyVaultInfo = '{"invalid":"structure"}'
    $global:MalformedJson = '{"KeyVault":{"URL":"https://test.vault.azure.net/"'
}

Describe "Get-KeyVaultInfo" {
    Context "Valid Key Vault Information" {
        It "should parse valid JSON and return correct properties" {
            $result = Get-KeyVaultInfo -KeyVaultInfo $global:TestKeyVaultInfo

            $result | Should -Not -BeNullOrEmpty
            $result.KeyVaultUrl | Should -Be "https://test-keyvault.vault.azure.net/"
            $result.KeyVaultCertificateName | Should -Be "test-certificate"
        }

        It "should return a PSCustomObject with correct property names" {
            $result = Get-KeyVaultInfo -KeyVaultInfo $global:TestKeyVaultInfo

            $result | Should -BeOfType [PSCustomObject]
            ($result | Get-Member -MemberType NoteProperty).Name | Should -Contain "KeyVaultUrl"
            ($result | Get-Member -MemberType NoteProperty).Name | Should -Contain "KeyVaultCertificateName"
        }
    }

    Context "Invalid Key Vault Information" {
        It "should throw error for malformed JSON" {
            { Get-KeyVaultInfo -KeyVaultInfo $global:MalformedJson } | Should -Throw
        }

        It "should throw error when KeyVault property is missing" {
            { Get-KeyVaultInfo -KeyVaultInfo $global:InvalidKeyVaultInfo } | Should -Throw "*KeyVault property not found*"
        }

        It "should throw error when URL is missing" {
            $missingUrl = @{
                KeyVault = @{
                    CertificateName = "test-certificate"
                }
            } | ConvertTo-Json

            { Get-KeyVaultInfo -KeyVaultInfo $missingUrl } | Should -Throw "*KeyVault URL not found*"
        }

        It "should throw error when CertificateName is missing" {
            $missingCert = @{
                KeyVault = @{
                    URL = "https://test-keyvault.vault.azure.net/"
                }
            } | ConvertTo-Json

            { Get-KeyVaultInfo -KeyVaultInfo $missingCert } | Should -Throw "*KeyVault CertificateName not found*"
        }

        It "should throw error for null or empty input" {
            { Get-KeyVaultInfo -KeyVaultInfo "" } | Should -Throw
            { Get-KeyVaultInfo -KeyVaultInfo $null } | Should -Throw
        }
    }
}

Describe "Get-KeyVaultSecret" {
    Context "Mocked Azure CLI Operations" {
        BeforeAll {
            function global:az {
                param()
                $arguments = $args -join " "
                if ($arguments -like "*my-secret*") {
                    return "secret-value-12345"
                }
                elseif ($arguments -like "*another-secret*") {
                    return "another-value-67890"
                }
                else {
                    return $null
                }
            }
        }

        AfterAll {
            Remove-Item -Path "function:\az" -ErrorAction SilentlyContinue
        }

        It "should retrieve a secret by name" {
            $result = Get-KeyVaultSecret -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -SecretName "my-secret" -Verbose:$false

            $result | Should -Be "secret-value-12345"
        }

        It "should retrieve a different secret by name" {
            $result = Get-KeyVaultSecret -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -SecretName "another-secret" -Verbose:$false

            $result | Should -Be "another-value-67890"
        }

        It "should throw when the secret is not found" {
            { Get-KeyVaultSecret -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -SecretName "nonexistent" -Verbose:$false } | Should -Throw "*Failed to retrieve secret*"
        }

        It "should throw when Azure CLI returns null" {
            function global:az { return $null }

            { Get-KeyVaultSecret -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -SecretName "my-secret" -Verbose:$false } | Should -Throw "*Failed to retrieve secret*"

            function global:az {
                param()
                $arguments = $args -join " "
                if ($arguments -like "*my-secret*") { return "secret-value-12345" }
                elseif ($arguments -like "*another-secret*") { return "another-value-67890" }
                else { return $null }
            }
        }

        It "should validate required parameters" {
            { Get-KeyVaultSecret -KeyVaultUrl "" -SecretName "test" } | Should -Throw
            { Get-KeyVaultSecret -KeyVaultUrl $null -SecretName "test" } | Should -Throw
            { Get-KeyVaultSecret -KeyVaultUrl "https://test.vault.azure.net/" -SecretName "" } | Should -Throw
            { Get-KeyVaultSecret -KeyVaultUrl "https://test.vault.azure.net/" -SecretName $null } | Should -Throw
        }
    }
}
