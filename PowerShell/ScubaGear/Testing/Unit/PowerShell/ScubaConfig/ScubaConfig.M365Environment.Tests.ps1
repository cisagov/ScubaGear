using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe 'ScubaConfig explicit environment tracking' {
    BeforeAll {
        function global:ConvertFrom-Yaml {
            param([Parameter(ValueFromPipeline = $true)]$Yaml)
            process {
                $Parsed = @{ ProductNames = @('aad') }
                if (($Yaml -join "`n") -match 'M365Environment:\s*(\w+)') {
                    $Parsed.M365Environment = $Matches[1]
                }
                return $Parsed
            }
        }
    }

    AfterEach {
        [ScubaConfig]::ResetInstance()
    }

    AfterAll {
        Remove-Item Function:\ConvertFrom-Yaml -ErrorAction SilentlyContinue
    }

    It 'distinguishes an explicit <Value> from the injected default' -TestCases @(
        @{ Value = 'commercial'; Expected = $true },
        @{ Value = 'gcchigh'; Expected = $true },
        @{ Value = ''; Expected = $false }
    ) {
        param($Value, $Expected)
        [ScubaConfig]::ResetInstance()
        $Path = Join-Path $TestDrive 'environment.yaml'
        $Yaml = "ProductNames: [aad]`n"
        if ($Value) {
            $Yaml += "M365Environment: $Value`n"
        }
        Set-Content -LiteralPath $Path -Value $Yaml
        $Config = [ScubaConfig]::GetInstance()
        $Config.LoadConfig($Path, $true) | Should -BeTrue
        $Config.M365EnvironmentProvided | Should -Be $Expected
        $Config.Configuration.M365Environment | Should -Be $(if ($Value) { $Value } else { 'commercial' })
    }
}
