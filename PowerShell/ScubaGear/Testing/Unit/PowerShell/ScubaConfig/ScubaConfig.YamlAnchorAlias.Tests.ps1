using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe "ScubaConfig YAML Anchor Definition Validation" {
    BeforeAll {
        # Initialize the system
        [ScubaConfig]::InitializeValidator()

        # Create a dummy OPA executable for testing (required for configuration validation)
        $IsLinuxOS = (Test-Path variable:IsLinux) -and $IsLinux
        $IsMacOSOS = (Test-Path variable:IsMacOS) -and $IsMacOS

        if ($IsLinuxOS) {
            $script:DummyOPAName = "opa_linux_amd64"
        }
        elseif ($IsMacOSOS) {
            $script:DummyOPAName = "opa_darwin_amd64"
        }
        else {
            $script:DummyOPAName = "opa_windows_amd64.exe"
        }
        $script:DummyOPAPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\..\..\$script:DummyOPAName"
        $script:DummyOPACreatedByTests = $false
        if (-not (Test-Path $script:DummyOPAPath)) {
            New-Item -Path $script:DummyOPAPath -ItemType File -Force | Out-Null
            $script:DummyOPACreatedByTests = $true
        }

        # Mock ConvertFrom-Yaml to avoid dependency on the powershell-yaml module in CI.
        # This mock does NOT resolve YAML anchors/aliases (that's ConvertFrom-Yaml's job in
        # production, not something the validator needs to reimplement) - it just needs to
        # produce a parsed object containing the same top-level keys as the raw file text,
        # since anchor detection reads the raw text directly rather than the parsed object.
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

                    if ($trimmed.StartsWith('- ')) {
                        if ($arrayMode -and $currentKey) {
                            $result[$currentKey] += @($trimmed.Substring(2).Trim())
                        }
                    }
                    elseif ($trimmed -match '^([^:]+):\s*(.*)$') {
                        $key = $matches[1].Trim()
                        $value = $matches[2].Trim()

                        if ($value -eq '') {
                            $result[$key] = @()
                            $currentKey = $key
                            $arrayMode = $true
                        }
                        else {
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

    BeforeEach {
        $script:TempFile = $null
    }

    AfterEach {
        [ScubaConfig]::ResetInstance()
        if ($script:TempFile -and (Test-Path $script:TempFile)) {
            Remove-Item -Path $script:TempFile -Force -ErrorAction SilentlyContinue
        }
    }

    AfterAll {
        [ScubaConfig]::ResetInstance()

        if ($script:DummyOPACreatedByTests -and (Test-Path $script:DummyOPAPath)) {
            Remove-Item -Path $script:DummyOPAPath -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Top-level keys that host a YAML anchor definition" {
        It "Should NOT flag an unknown property warning for a root key whose value carries an anchor" {
            $Yaml = @"
OrgName: TestOrg
ProductNames:
  - aad
M365Environment: commercial
SensitiveUsers: &CommonSensitiveUsers
  - Example User;exampleuser@example.onmicrosoft.com
"@
            $script:TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $Yaml | Set-Content -Path $script:TempFile

            $Result = [ScubaConfig]::ValidateConfigFile($script:TempFile)

            $Result.Warnings | Where-Object { $_ -match "Unknown property 'SensitiveUsers'" } | Should -BeNullOrEmpty
        }

        It "Should NOT flag an unknown property warning regardless of the anchor host key's name" {
            $Yaml = @"
OrgName: TestOrg
ProductNames:
  - aad
M365Environment: commercial
CommonExclusions: &CommonExclusions
  - someone@example.onmicrosoft.com
"@
            $script:TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $Yaml | Set-Content -Path $script:TempFile

            $Result = [ScubaConfig]::ValidateConfigFile($script:TempFile)

            $Result.Warnings | Where-Object { $_ -match "Unknown property 'CommonExclusions'" } | Should -BeNullOrEmpty
        }

        It "Should still flag an unknown property warning for the same key name when it has no anchor" {
            $Yaml = @"
OrgName: TestOrg
ProductNames:
  - aad
M365Environment: commercial
SensitiveUsers: SomeGenericValue
"@
            $script:TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $Yaml | Set-Content -Path $script:TempFile

            $Result = [ScubaConfig]::ValidateConfigFile($script:TempFile)

            $Result.Warnings | Where-Object { $_ -match "Unknown property 'SensitiveUsers'" } | Should -Not -BeNullOrEmpty
        }

        It "Should still flag unrelated unknown properties that don't carry an anchor" {
            $Yaml = @"
OrgName: TestOrg
ProductNames:
  - aad
M365Environment: commercial
SensitiveUsers: &CommonSensitiveUsers
  - Example User;exampleuser@example.onmicrosoft.com
TotallyMadeUpProperty: SomeValue
"@
            $script:TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            $Yaml | Set-Content -Path $script:TempFile

            $Result = [ScubaConfig]::ValidateConfigFile($script:TempFile)

            $Result.Warnings | Where-Object { $_ -match "Unknown property 'SensitiveUsers'" } | Should -BeNullOrEmpty
            $Result.Warnings | Where-Object { $_ -match "Unknown property 'TotallyMadeUpProperty'" } | Should -Not -BeNullOrEmpty
        }
    }
}
