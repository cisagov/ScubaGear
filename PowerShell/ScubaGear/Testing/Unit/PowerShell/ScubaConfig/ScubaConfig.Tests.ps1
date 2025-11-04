using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe "ScubaConfig JSON-based Configuration Tests" {
    BeforeAll {
        # Reset the instance before tests
        [ScubaConfig]::ResetInstance()
    }

    AfterEach {
        # Reset the instance after each test to prevent state bleed
        [ScubaConfig]::ResetInstance()
    }

    AfterAll {
        # Clean up after tests
        [ScubaConfig]::ResetInstance()
    }

    It "Should load JSON configuration defaults" {
        $Defaults = [ScubaConfig]::GetConfigDefaults()

        $Defaults | Should -Not -BeNullOrEmpty
        $Defaults.defaults | Should -Not -BeNullOrEmpty
        $Defaults.defaults.ProductNames | Should -Contain "aad"
        $Defaults.defaults.M365Environment | Should -Be "commercial"
        $Defaults.defaults.OPAVersion | Should -Match "^\d+\.\d+\.\d+$"
    }

    It "Should validate valid YAML configuration" {
        $ValidYaml = @"
ProductNames:
  - aad
  - defender
M365Environment: commercial
Organization: example.onmicrosoft.com
OrgName: Test Organization
OrgUnitName: IT Department
"@

        $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
        $ValidYaml | Set-Content -Path $TempFile

        $ValidationResult = [ScubaConfig]::ValidateConfigFile($TempFile)

        $ValidationResult.IsValid | Should -Be $True
        $ValidationResult.ValidationErrors | Should -BeNullOrEmpty

        Remove-Item -Path $TempFile -Force
    }

    It "Should reject invalid YAML configuration" {
        $InvalidYaml = @"
ProductNames:
  - invalid_product
M365Environment: invalid_environment
Organization: invalid_format
"@

        $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
        $InvalidYaml | Set-Content -Path $TempFile

        $ValidationResult = [ScubaConfig]::ValidateConfigFile($TempFile)

        $ValidationResult.IsValid | Should -Be $False
        $ValidationResult.ValidationErrors.Count | Should -BeGreaterThan 0

        Remove-Item -Path $TempFile -Force
    }

    It "Should validate policy IDs correctly" {
        $YamlWithPolicies = @"
ProductNames:
  - aad
  - defender
OmitPolicy:
  MS.AAD.1.1v1: "Valid policy ID"
  invalid_policy: "Invalid policy ID"
AnnotatePolicy:
  MS.DEFENDER.2.1v1: "Valid annotation"
"@

        $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
        $YamlWithPolicies | Set-Content -Path $TempFile

        $ValidationResult = [ScubaConfig]::ValidateConfigFile($TempFile)

        # Should have validation errors for invalid policy ID
        $ValidationResult.ValidationErrors | Should -Contain "Policy ID 'invalid_policy' does not match expected format. Expected: MS.DEFENDER.1.1v1"

        Remove-Item -Path $TempFile -Force
    }

    It "Should handle exclusions configuration" {
        $YamlWithExclusions = @"
ProductNames:
  - aad
  - defender
M365Environment: commercial
Organization: example.onmicrosoft.com
OrgName: Test Organization
OrgUnitName: IT Department
ExclusionsConfig:
  aad:
    CapExclusions:
      Users:
        - "user1@example.com"
      Groups:
        - "Group1"
  defender:
    SensitiveUsers:
      - DisplayName: "John Doe"
        EmailAddress: "john.doe@example.com"
"@

        $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
        $YamlWithExclusions | Set-Content -Path $TempFile

        $ValidationResult = [ScubaConfig]::ValidateConfigFile($TempFile)

        $ValidationResult.IsValid | Should -Be $True

        Remove-Item -Path $TempFile -Force
    }

    It "Should get product information" {
        $AadInfo = [ScubaConfig]::GetProductInfo("aad")

        $AadInfo | Should -Not -BeNullOrEmpty
        $AadInfo.name | Should -Be "Microsoft Entra ID"
        $AadInfo.supportsExclusions | Should -Be $True
        $AadInfo.supportedExclusionTypes | Should -Contain "CapExclusions"
    }

    It "Should get supported products and environments" {
        $Products = [ScubaConfig]::GetSupportedProducts()
        $Environments = [ScubaConfig]::GetSupportedEnvironments()

        $Products | Should -Contain "aad"
        $Products | Should -Contain "powerplatform"

        $Environments | Should -Contain "commercial"
        $Environments | Should -Contain "gcc"
    }

    It "Should maintain backward compatibility with ScubaDefault method" {
        $OpaVersion = [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
        $ProductNames = [ScubaConfig]::ScubaDefault('DefaultProductNames')

        $OpaVersion | Should -Match "^\d+\.\d+\.\d+$"
        $ProductNames | Should -Contain "aad"
    }

    It "Should load configuration with validation" {
        $ValidYaml = @"
ProductNames:
  - aad
  - teams
M365Environment: gcc
Organization: testorg.onmicrosoft.us
OrgName: Test Government Organization
OrgUnitName: IT Department
LogIn: false
OutFolderName: CustomOutputFolder
"@

        $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
        $ValidYaml | Set-Content -Path $TempFile

        $Config = [ScubaConfig]::GetInstance()
        $LoadResult = $Config.LoadConfig($TempFile)

        $LoadResult | Should -Be $True
        $Config.Configuration.ProductNames | Should -Contain "aad"
        $Config.Configuration.ProductNames | Should -Contain "teams"
        $Config.Configuration.M365Environment | Should -Be "gcc"
        $Config.Configuration.OutFolderName | Should -Be "CustomOutputFolder"

        Remove-Item -Path $TempFile -Force
    }
}
