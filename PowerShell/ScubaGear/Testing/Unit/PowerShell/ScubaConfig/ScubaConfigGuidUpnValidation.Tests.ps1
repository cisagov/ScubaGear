#Requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.0.0'}
using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigValidator.psm1'

BeforeAll {
    # Import required modules
    Import-Module powershell-yaml -Force -ErrorAction Stop

    # Initialize the validator
    [ScubaConfigValidator]::Initialize("$PSScriptRoot\..\..\..\..\Modules\ScubaConfig")

    # Test YAML configurations
    $script:ValidConfigYaml = @"
ProductNames:
  - aad
  - defender

ExclusionsConfig:
  aad:
    CapExclusions:
      Users:
        - "12345678-1234-1234-1234-123456789abc"
      Groups:
        - "87654321-4321-4321-4321-cba987654321"
    RoleExclusions:
      Users:
        - "11111111-2222-3333-4444-555555555555"
  defender:
    SensitiveAccounts:
      IncludedUsers:
        - "user@example.com"
        - "admin@company.org"
      ExcludedUsers:
        - "testuser@example.com"
"@

    $script:InvalidGuidConfigYaml = @"
ProductNames:
  - aad

ExclusionsConfig:
  aad:
    CapExclusions:
      Users:
        - "not-a-guid"
        - "invalid-format"
      Groups:
        - "also-not-guid"
"@

    $script:InvalidUpnConfigYaml = @"
ProductNames:
  - defender

ExclusionsConfig:
  defender:
    SensitiveAccounts:
      IncludedUsers:
        - "not-an-email"
        - "invalid.format"
      ExcludedUsers:
        - "also@invalid"
"@
}

Describe "GUID and UPN Validation in Exclusions" {
    Context "Valid Configurations" {
        It "Should validate configuration with proper GUIDs and UPNs" {
            $script:ValidConfigYaml | Out-File -FilePath "TestData_Valid.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_Valid.yaml")
                Write-Host "Debug: Validation errors: $($result.ValidationErrors -join '; ')"
                $result.IsValid | Should -Be $true
                $result.ValidationErrors.Count | Should -Be 0
            }
            finally {
                Remove-Item "TestData_Valid.yaml" -ErrorAction SilentlyContinue
            }
        }

        It "Should accept valid GUID format in AAD CapExclusions" {
            $validGuid = "12345678-1234-1234-1234-123456789abc"
            $validGuid | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        }

        It "Should accept valid UPN format in Defender SensitiveAccounts" {
            $validUpn = "user@example.com"
            $validUpn | Should -Match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        }
    }

    Context "Invalid GUID Configurations" {
        It "Should reject configuration with invalid GUIDs in AAD CapExclusions" {
            $script:InvalidGuidConfigYaml | Out-File -FilePath "TestData_InvalidGuid.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_InvalidGuid.yaml")
                $result.IsValid | Should -Be $false
                $result.ValidationErrors.Count | Should -BeGreaterThan 0

                # Check that errors mention GUID format
                $guidErrors = $result.ValidationErrors | Where-Object { $_ -like "*GUID format*" }
                $guidErrors.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item "TestData_InvalidGuid.yaml" -ErrorAction SilentlyContinue
            }
        }

        It "Should reject invalid GUID formats" {
            $invalidGuids = @(
                "not-a-guid",
                "invalid-format",
                "12345678-1234-1234-1234",  # Too short
                "12345678-1234-1234-1234-123456789abcd",  # Too long
                "gggggggg-1234-1234-1234-123456789abc"   # Invalid characters
            )

            foreach ($invalidGuid in $invalidGuids) {
                $invalidGuid | Should -Not -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
            }
        }
    }

    Context "Invalid UPN Configurations" {
        It "Should reject configuration with invalid UPNs in Defender SensitiveAccounts" {
            $script:InvalidUpnConfigYaml | Out-File -FilePath "TestData_InvalidUpn.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_InvalidUpn.yaml")
                $result.IsValid | Should -Be $false
                $result.ValidationErrors.Count | Should -BeGreaterThan 0

                # Check that errors mention UPN format
                $upnErrors = $result.ValidationErrors | Where-Object { $_ -like "*UPN format*" }
                $upnErrors.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item "TestData_InvalidUpn.yaml" -ErrorAction SilentlyContinue
            }
        }

        It "Should reject invalid UPN formats" {
            $invalidUpns = @(
                "not-an-email",
                "invalid.format",
                "missing@",
                "@missing-local",
                "no-domain@",
                "space @example.com",
                "also@invalid"  # Missing TLD
            )

            foreach ($invalidUpn in $invalidUpns) {
                $invalidUpn | Should -Not -Match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            }
        }
    }

    Context "Format Requirements" {
        It "Should require GUIDs for AAD CapExclusions Users" {
            # This is a business rule test
            $config = @"
ProductNames:
  - aad
ExclusionsConfig:
  aad:
    CapExclusions:
      Users:
        - "user@example.com"
"@
            $config | Out-File -FilePath "TestData_EmailInGuid.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_EmailInGuid.yaml")
                $result.IsValid | Should -Be $false
                ($result.ValidationErrors -join " ") | Should -Match "GUID format"
            }
            finally {
                Remove-Item "TestData_EmailInGuid.yaml" -ErrorAction SilentlyContinue
            }
        }

        It "Should require UPNs for Defender SensitiveAccounts Users" {
            # This is a business rule test
            $config = @"
ProductNames:
  - defender
ExclusionsConfig:
  defender:
    SensitiveAccounts:
      IncludedUsers:
        - "12345678-1234-1234-1234-123456789abc"
"@
            $config | Out-File -FilePath "TestData_GuidInUpn.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_GuidInUpn.yaml")
                $result.IsValid | Should -Be $false
                ($result.ValidationErrors -join " ") | Should -Match "UPN format"
            }
            finally {
                Remove-Item "TestData_GuidInUpn.yaml" -ErrorAction SilentlyContinue
            }
        }
    }
}
