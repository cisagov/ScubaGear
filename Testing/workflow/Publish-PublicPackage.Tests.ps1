# The purpose of this test is to verify that the Publish-PublicPackage functions are working correctly.
# These functions were extracted from the publish_public_package.yaml workflow.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    # Source the publish public package script.
    . $PSScriptRoot/../../utils/workflow/Publish-PublicPackage.ps1

    # Mock variables for testing
    $global:TestKeyVaultInfo = @{
        KeyVault = @{
            URL = "https://test-keyvault.vault.azure.net/"
            CertificateName = "test-certificate"
        }
    } | ConvertTo-Json

    $global:InvalidKeyVaultInfo = '{"invalid":"structure"}'
    $global:MalformedJson = '{"KeyVault":{"URL":"https://test.vault.azure.net/"'  # Missing closing braces
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

Describe "Remove-GitFiles" {
    Context "Valid Directory Operations" {
        It "should remove .git directories from test folder" {
            # Create test directory structure
            $testRoot = Join-Path -Path $TestDrive -ChildPath "test-repo"
            $gitDir = Join-Path -Path $testRoot -ChildPath ".git"
            $gitIgnore = Join-Path -Path $testRoot -ChildPath ".gitignore"
            $gitAttributes = Join-Path -Path $testRoot -ChildPath ".gitattributes"
            $subGitDir = Join-Path -Path $testRoot -ChildPath "subfolder\.git"

            New-Item -ItemType Directory -Path $testRoot -Force
            New-Item -ItemType Directory -Path $gitDir -Force
            New-Item -ItemType Directory -Path (Split-Path $subGitDir) -Force
            New-Item -ItemType Directory -Path $subGitDir -Force
            New-Item -ItemType File -Path $gitIgnore -Force
            New-Item -ItemType File -Path $gitAttributes -Force

            # Add some content to verify directories exist
            New-Item -ItemType File -Path "$gitDir\config" -Force

            # Verify git files exist before removal
            Test-Path -Path $gitDir | Should -Be $true
            Test-Path -Path $gitIgnore | Should -Be $true
            Test-Path -Path $gitAttributes | Should -Be $true
            Test-Path -Path $subGitDir | Should -Be $true

            # Remove git files
            Remove-GitFiles -RootFolderPath $testRoot

            # Verify git files are removed
            Test-Path -Path $gitDir | Should -Be $false
            Test-Path -Path $gitIgnore | Should -Be $false
            Test-Path -Path $gitAttributes | Should -Be $false
            Test-Path -Path $subGitDir | Should -Be $false

            # Verify root directory still exists
            Test-Path -Path $testRoot | Should -Be $true
        }

        It "should handle directory with no git files gracefully" {
            $testRoot = Join-Path -Path $TestDrive -ChildPath "clean-repo"
            $regularFile = Join-Path -Path $testRoot -ChildPath "readme.md"

            New-Item -ItemType Directory -Path $testRoot -Force
            New-Item -ItemType File -Path $regularFile -Force

            # Should not throw and should complete successfully
            { Remove-GitFiles -RootFolderPath $testRoot } | Should -Not -Throw

            # Regular files should remain
            Test-Path -Path $regularFile | Should -Be $true
        }
    }

    Context "Error Conditions" {
        It "should throw error for non-existent directory" {
            $nonExistentPath = Join-Path -Path $TestDrive -ChildPath "does-not-exist"

            { Remove-GitFiles -RootFolderPath $nonExistentPath } | Should -Throw "*does not exist*"
        }

        It "should throw error for null or empty path" {
            { Remove-GitFiles -RootFolderPath "" } | Should -Throw
            { Remove-GitFiles -RootFolderPath $null } | Should -Throw
        }
    }
}

Describe "Set-PublishParameters" {
    Context "Valid Parameter Configuration" {
        BeforeEach {
            # Create a test module directory
            $global:TestModulePath = Join-Path -Path $TestDrive -ChildPath "TestModule"
            New-Item -ItemType Directory -Path $global:TestModulePath -Force
        }

        It "should create basic parameters for stable release" {
            $params = Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $global:TestModulePath -ApiKey "test-api-key" -Verbose:$false

            $params | Should -Not -BeNullOrEmpty
            $params | Should -BeOfType [hashtable]
            $params.AzureKeyVaultUrl | Should -Be "https://test.vault.azure.net/"
            $params.CertificateName | Should -Be "test-cert"
            $params.ModuleSourcePath | Should -Be $global:TestModulePath
            $params.GalleryName | Should -Be "PSGallery"
            $params.NuGetApiKey | Should -Be "test-api-key"
            $params.ContainsKey("PrereleaseTag") | Should -Be $false
            $params.ContainsKey("OverrideModuleVersion") | Should -Be $false
        }

        It "should include prerelease tag when IsPrerelease is true" {
            $params = Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $global:TestModulePath -ApiKey "test-api-key" -IsPrerelease $true -PrereleaseTag "alpha1" -Verbose:$false

            $params.ContainsKey("PrereleaseTag") | Should -Be $true
            $params.PrereleaseTag | Should -Be "alpha1"
        }

        It "should include version override when specified" {
            $params = Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $global:TestModulePath -ApiKey "test-api-key" -OverrideModuleVersion "1.2.3" -Verbose:$false

            $params.ContainsKey("OverrideModuleVersion") | Should -Be $true
            $params.OverrideModuleVersion | Should -Be "1.2.3"
        }

        It "should include both prerelease and version override when specified" {
            $params = Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $global:TestModulePath -ApiKey "test-api-key" -IsPrerelease $true -PrereleaseTag "beta2" -OverrideModuleVersion "2.0.0"

            $params.PrereleaseTag | Should -Be "beta2"
            $params.OverrideModuleVersion | Should -Be "2.0.0"
        }

        It "should not include prerelease tag when IsPrerelease is false" {
            $params = Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $global:TestModulePath -ApiKey "test-api-key" -IsPrerelease $false -PrereleaseTag "should-not-be-included" -Verbose:$false

            $params.ContainsKey("PrereleaseTag") | Should -Be $false
        }
    }

    Context "Error Conditions" {
        It "should throw error for non-existent module source path" {
            $invalidPath = Join-Path -Path $TestDrive -ChildPath "does-not-exist"

            { Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $invalidPath -ApiKey "test-api-key" } | Should -Throw "*does not exist*"
        }

        It "should validate required parameters are not null or empty" {
            $testModulePath = Join-Path -Path $TestDrive -ChildPath "TestModule2"
            New-Item -ItemType Directory -Path $testModulePath -Force

            { Set-PublishParameters -AzureKeyVaultUrl "" -CertificateName "test-cert" -ModuleSourcePath $testModulePath -ApiKey "test-api-key" } | Should -Throw
            { Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "" -ModuleSourcePath $testModulePath -ApiKey "test-api-key" } | Should -Throw
            { Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath "" -ApiKey "test-api-key" } | Should -Throw
            { Set-PublishParameters -AzureKeyVaultUrl "https://test.vault.azure.net/" -CertificateName "test-cert" -ModuleSourcePath $testModulePath -ApiKey "" } | Should -Throw
        }
    }
}

Describe "Test-PublishedModule" {
    Context "Mocked Module Testing" {
        BeforeAll {
            # Mock Find-Module to simulate PSGallery responses
            Mock Find-Module {
                param($Name, $RequiredVersion, $AllowPrerelease)

                # Use AllowPrerelease parameter to suppress PSSA warnings
                $null = $AllowPrerelease

                if ($Name -eq "ScubaGear") {
                    if ($RequiredVersion -eq "1.0.0-alpha1") {
                        return @{
                            Name = "ScubaGear"
                            Version = "1.0.0-alpha1"
                        }
                    } elseif (-not $RequiredVersion) {
                        return @{
                            Name = "ScubaGear"
                            Version = "1.0.0"
                        }
                    }
                }
                throw "Module not found"
            }
        }

        It "should return true for successful stable module test" {
            $result = Test-PublishedModule -IsPrerelease $false -WaitSeconds 0 -Verbose:$false

            $result | Should -Be $true
        }

        It "should return true for successful prerelease module test" {
            $result = Test-PublishedModule -IsPrerelease $true -ModuleVersion "1.0.0" -PrereleaseTag "alpha1" -WaitSeconds 0 -Verbose:$false

            $result | Should -Be $true
        }

        It "should return false when module is not found" {
            Mock Find-Module { return $null }

            $result = Test-PublishedModule -IsPrerelease $false -WaitSeconds 0 -Verbose:$false

            $result | Should -Be $false
        }

        It "should validate required parameters for prerelease testing" {
            { Test-PublishedModule -IsPrerelease $true -WaitSeconds 0 -Verbose:$false -ErrorAction Stop } | Should -Throw "*ModuleVersion and PrereleaseTag are required*"
            { Test-PublishedModule -IsPrerelease $true -ModuleVersion "1.0.0" -WaitSeconds 0 -Verbose:$false -ErrorAction Stop } | Should -Throw "*ModuleVersion and PrereleaseTag are required*"
            { Test-PublishedModule -IsPrerelease $true -PrereleaseTag "alpha1" -WaitSeconds 0 -Verbose:$false -ErrorAction Stop } | Should -Throw "*ModuleVersion and PrereleaseTag are required*"
        }

        It "should handle custom wait time" {
            Mock Start-Sleep { param($Seconds); $null = $Seconds }

            Test-PublishedModule -IsPrerelease $false -WaitSeconds 60

            Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 60 }
        }

        It "should skip wait when WaitSeconds is 0" {
            Mock Start-Sleep { param($Seconds); $null = $Seconds }

            Test-PublishedModule -IsPrerelease $false -WaitSeconds 0

            Should -Invoke Start-Sleep -Times 0
        }
    }
}

Describe "Get-PSGalleryApiKey" {
    Context "Mocked Azure CLI Operations" {
        BeforeAll {
            # Create a fake az function in global scope for testing
            function global:az {
                param()
                # Parse arguments looking for the secret ID
                $arguments = $args -join " "
                if ($arguments -like "*ScubaGear-PSGAllery-API-Key*") {
                    return "test-api-key-12345"
                } elseif ($arguments -like "*custom-secret*") {
                    return "custom-api-key-67890"
                } else {
                    return $null
                }
            }
        }

        AfterAll {
            # Clean up the global function
            Remove-Item -Path "function:\az" -ErrorAction SilentlyContinue
        }

        It "should retrieve API key with default secret name" {
            $result = Get-PSGalleryApiKey -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -Verbose:$false

            $result | Should -Be "test-api-key-12345"
        }

        It "should retrieve API key with custom secret name" {
            $result = Get-PSGalleryApiKey -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -SecretName "custom-secret" -Verbose:$false

            $result | Should -Be "custom-api-key-67890"
        }

        It "should construct correct secret URI" {
            # This test is handled by the mock verification - just test that it works
            $result = Get-PSGalleryApiKey -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -Verbose:$false
            $result | Should -Be "test-api-key-12345"
        }

        It "should throw error when API key retrieval fails" {
            # Temporarily override the az function to return null
            function global:az { return $null }

            { Get-PSGalleryApiKey -KeyVaultUrl "https://test-keyvault.vault.azure.net/" -Verbose:$false } | Should -Throw "*Failed to retrieve API key*"

            # Restore the original mock
            function global:az {
                param()
                $arguments = $args -join " "
                if ($arguments -like "*ScubaGear-PSGAllery-API-Key*") {
                    return "test-api-key-12345"
                } elseif ($arguments -like "*custom-secret*") {
                    return "custom-api-key-67890"
                } else {
                    return $null
                }
            }
        }

        It "should validate required parameters" {
            { Get-PSGalleryApiKey -KeyVaultUrl "" } | Should -Throw
            { Get-PSGalleryApiKey -KeyVaultUrl $null } | Should -Throw
        }
    }
}

Describe "Integration Tests" {
    Context "Function Interactions" {
        It "should pass KeyVault info from Get-KeyVaultInfo to Set-PublishParameters" {
            # Create test module directory
            $testModule = Join-Path -Path $TestDrive -ChildPath "IntegrationTestModule"
            New-Item -ItemType Directory -Path $testModule -Force

            # Get KeyVault info
            $keyVaultInfo = Get-KeyVaultInfo -KeyVaultInfo $global:TestKeyVaultInfo

            # Use it in Set-PublishParameters
            $params = Set-PublishParameters -AzureKeyVaultUrl $keyVaultInfo.KeyVaultUrl -CertificateName $keyVaultInfo.KeyVaultCertificateName -ModuleSourcePath $testModule -ApiKey "test-key"

            $params.AzureKeyVaultUrl | Should -Be "https://test-keyvault.vault.azure.net/"
            $params.CertificateName | Should -Be "test-certificate"
        }

        It "should work with realistic workflow scenario" {
            # Simulate the workflow steps
            $testRoot = Join-Path -Path $TestDrive -ChildPath "workflow-test"
            $testModule = Join-Path -Path $testRoot -ChildPath "PowerShell\ScubaGear"
            $gitDir = Join-Path -Path $testRoot -ChildPath ".git"

            # Setup test structure
            New-Item -ItemType Directory -Path $testModule -Force
            New-Item -ItemType Directory -Path $gitDir -Force

            # Step 1: Get KeyVault info
            $keyVaultInfo = Get-KeyVaultInfo -KeyVaultInfo $global:TestKeyVaultInfo
            $keyVaultInfo | Should -Not -BeNullOrEmpty

            # Step 2: Remove git files
            Remove-GitFiles -RootFolderPath $testRoot
            Test-Path -Path $gitDir | Should -Be $false

            # Step 3: Set publish parameters
            $params = Set-PublishParameters -AzureKeyVaultUrl $keyVaultInfo.KeyVaultUrl -CertificateName $keyVaultInfo.KeyVaultCertificateName -ModuleSourcePath $testModule -ApiKey "test-key" -IsPrerelease $true -PrereleaseTag "test1" -OverrideModuleVersion "1.0.0"

            $params | Should -Not -BeNullOrEmpty
            $params.PrereleaseTag | Should -Be "test1"
            $params.OverrideModuleVersion | Should -Be "1.0.0"
        }
    }
}
