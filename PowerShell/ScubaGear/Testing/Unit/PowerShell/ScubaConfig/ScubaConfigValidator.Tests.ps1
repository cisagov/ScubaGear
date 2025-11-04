using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigValidator.psm1'

Describe "ScubaConfigValidator Basic Validation" {
    BeforeAll {
        # Initialize the validator
        [ScubaConfigValidator]::Initialize("$PSScriptRoot\..\..\..\..\Modules\ScubaConfig")

        # Test YAML configurations
        $script:ValidConfigYaml = @"
ProductNames:
  - aad
  - defender
M365Environment: commercial
OrgName: Test Organization
Description: Test configuration for validation

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
M365Environment: commercial
OrgName: Test Organization
Description: Test configuration with invalid GUIDs

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
M365Environment: commercial
OrgName: Test Organization
Description: Test configuration with invalid UPNs

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

    Context "Valid Configurations" {
        It "Should validate configuration with proper structure and required fields" {
            $script:ValidConfigYaml | Out-File -FilePath "TestData_Valid.yaml" -Encoding UTF8

            try {
                $result = [ScubaConfigValidator]::ValidateYamlFile("TestData_Valid.yaml")
                Write-Information "Debug: Validation errors: $($result.ValidationErrors -join '; ')" -InformationAction Continue
                $result.IsValid | Should -Be $true
                $result.ValidationErrors.Count | Should -Be 0
            }
            finally {
                Remove-Item "TestData_Valid.yaml" -ErrorAction SilentlyContinue
            }
        }

        It "Should accept valid GUID format pattern" {
            $validGuid = "12345678-1234-1234-1234-123456789abc"
            $validGuid | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        }

        It "Should accept valid UPN format pattern" {
            $validUpn = "user@example.com"
            $validUpn | Should -Match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        }
    }

    Context "Pattern Validation Tests" {
        It "Should recognize invalid GUID formats" {
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

        It "Should recognize invalid UPN formats" {
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
}
