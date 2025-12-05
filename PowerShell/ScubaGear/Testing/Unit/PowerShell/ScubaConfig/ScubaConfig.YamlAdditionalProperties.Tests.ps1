using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe "ScubaConfig Additional Properties Validation" {
    BeforeAll {
        # Initialize the system
        [ScubaConfig]::InitializeValidator()

        # Mock ConvertFrom-Yaml to avoid dependency on powershell-yaml module in CI
        # This mock parses simple YAML structures that our tests use
        function global:ConvertFrom-Yaml {
            [CmdletBinding()]
            param([Parameter(ValueFromPipeline)]$YamlString)

            process {
                if (-not $YamlString) { return @{} }

                $result = @{}
                $lines = $YamlString -split "`n" | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }
                $currentKey = $null
                $arrayMode = $false

                foreach ($line in $lines) {
                    $trimmed = $line.Trim()

                    # Handle array items
                    if ($trimmed.StartsWith('- ')) {
                        if ($arrayMode -and $currentKey) {
                            $result[$currentKey] += @($trimmed.Substring(2).Trim())
                        }
                    }
                    # Handle key-value pairs
                    elseif ($trimmed -match '^([^:]+):\s*(.*)$') {
                        $key = $matches[1].Trim()
                        $value = $matches[2].Trim()

                        if ($value -eq '') {
                            # Start of array
                            $result[$key] = @()
                            $currentKey = $key
                            $arrayMode = $true
                        }
                        elseif ($value -match '^\{.*\}$') {
                            # Inline object - skip for now
                            $result[$key] = @{}
                        }
                        else {
                            # Simple value - parse boolean types correctly
                            if ($value -eq 'true' -or $value -eq 'True') {
                                $result[$key] = $true
                            }
                            elseif ($value -eq 'false' -or $value -eq 'False') {
                                $result[$key] = $false
                            }
                            else {
                                $result[$key] = $value
                            }
                            $arrayMode = $false
                        }
                    }
                }

                return $result
            }
        }
    }

    AfterEach {
        # Reset the instance after each test to prevent state bleed
        [ScubaConfig]::ResetInstance()
    }

    AfterAll {
        # Clean up after tests
        [ScubaConfig]::ResetInstance()
    }

    Context "Valid root-level properties" {
        It "Should accept configuration with only documented properties" {
            $ValidYaml = @"
ProductNames:
  - aad
  - teams
M365Environment: commercial
OPAPath: .
OutPath: .
OutFolderName: M365BaselineConformance
OutProviderFileName: ProviderSettingsExport
OutRegoFileName: TestResults
OutReportName: BaselineReports
DisconnectOnExit: false
SkipDoH: false
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force
        }

        It "Should accept configuration with optional authentication properties" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
AppId: 12345678-1234-1234-1234-123456789012
CertificateThumbprint: 1234567890ABCDEF1234567890ABCDEF12345678
Organization: example.com
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force
        }

    }

    Context "Invalid root-level properties (additionalProperties: true allows custom properties)" {
        It "Should ALLOW configuration with custom root-level property" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
CustomProperty: this-is-now-allowed
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should ALLOW configuration with typo in ProductNames (ProductName) because ProductNames has a default" -Tag "test-typo" {
            $YamlWithTypo = @"
ProductName:
  - aad
M365Environment: commercial
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            # Ensure we're writing fresh content
            if (Test-Path $TempFile) {
                Remove-Item $TempFile -Force
            }
            $YamlWithTypo | Set-Content -Path $TempFile -Force

            [ScubaConfig]::ResetInstance()
            $Config = [ScubaConfig]::GetInstance()
            # ProductNames is not in the file, but has a default value, so config loads successfully
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            # ProductName (typo) should be treated as a custom property
            $Config.Configuration.ProductName | Should -Not -BeNullOrEmpty
            $Config.Configuration.ProductName | Should -Contain 'aad'

            # ProductNames (correct) should come from default (not from typo)
            $Config.Configuration.ProductNames | Should -Not -BeNullOrEmpty
            # Default value should be applied
            $Config.Configuration.ProductNames.Count | Should -BeGreaterThan 1

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should ALLOW configuration with custom property alongside required properties" {
            $ValidYaml = @"
ProductNames:
  - aad
Environment: commercial
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            # Environment is custom property, should be allowed
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should ALLOW configuration with arbitrary custom fields" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
MyCustomField: value
AnotherCustomField: value2
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should ALLOW configuration with snake_case custom properties" {
            $ValidYaml = @"
ProductNames:
  - aad
m365_environment: commercial
custom_field: value
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should provide access to custom properties" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
MyCustomProperty: test-value
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            [ScubaConfig]::ResetInstance()
            $Config = [ScubaConfig]::GetInstance()
            $Config.LoadConfig($TempFile)
            $Config.Configuration.MyCustomProperty | Should -Be 'test-value'

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }

        It "Should allow multiple custom properties" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
CustomProp1: value1
CustomProp2: value2
CustomProp3: value3
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            [ScubaConfig]::ResetInstance()
            $Config = [ScubaConfig]::GetInstance()
            $Config.LoadConfig($TempFile)
            $Config.Configuration.CustomProp1 | Should -Be 'value1'
            $Config.Configuration.CustomProp2 | Should -Be 'value2'
            $Config.Configuration.CustomProp3 | Should -Be 'value3'

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Edge cases for additionalProperties validation" {
        It "Should allow all valid properties simultaneously" {
            $ValidYaml = @"
ProductNames:
  - aad
  - teams
M365Environment: commercial
OPAPath: .
OutPath: .
OutFolderName: M365BaselineConformance
OutProviderFileName: ProviderSettingsExport
OutRegoFileName: TestResults
OutReportName: BaselineReports
DisconnectOnExit: false
AppId: 12345678-1234-1234-1234-123456789012
CertificateThumbprint: 1234567890ABCDEF1234567890ABCDEF12345678
Organization: example.com
OrgName: Example Organization
OrgUnitName: IT Department
PreferredDnsResolvers:
  - 8.8.8.8
  - 1.1.1.1
SkipDoH: false
OmitPolicy:
  MS.AAD.1.1v1: Test omission
AnnotatePolicy:
  MS.TEAMS.2.1v1: Test annotation
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force
        }

        It "Should differentiate between product-level exclusions (allowed) and root-level custom properties (not allowed)" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
aad:
  CapExclusions:
    Users:
      - "12345678-1234-1234-1234-123456789012"
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force
        }

        It "Should allow unknown product name as custom property at root level" {
            $ValidYaml = @"
ProductNames:
  - aad
M365Environment: commercial
unknownproduct:
  SomeConfig: value
"@

            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $ValidYaml | Set-Content -Path $TempFile

            $Config = [ScubaConfig]::GetInstance()
            { $Config.LoadConfig($TempFile) } | Should -Not -Throw

            Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
        }
    }
}
