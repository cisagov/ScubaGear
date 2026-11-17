Describe -Tag 'Analyzer' -Name 'MS.EXO.1.1v2 default remote domain handling' {
    BeforeAll {
        $script:root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $helpers = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzerHelpers'
        $script:moduleNames = foreach ($file in Get-ChildItem $helpers -Filter '*.psm1') {
            Import-Module $file.FullName -Force
            $file.BaseName
        }
        $script:state = [hashtable]::Synchronized(@{})
        foreach ($name in $moduleNames) {
            & (Get-Module $name) { param($State) $script:syncHash = $State } $state
        }
        $script:paths = @{
            BaselineSchemaPath  = Join-Path $root 'schemas\ScubaGearResultsBaselineSchema.json'
            AnalyzerControlPath = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzer_Control_en-US.json'
            ConfigSchemaPath    = Join-Path $root 'schemas\ScubaConfigSchema.json'
        }

        function Get-ExoFinding {
            param($RemoteDomains)
            $data = @{}
            if ($null -ne $RemoteDomains) { $data.remote_domains = @($RemoteDomains) }
            $scan = Invoke-ScubaTenantScan -Product exo -TenantData $data @paths
            @($scan.Findings | Where-Object ControlId -EQ 'MS.EXO.1.1v2')[0]
        }
        function Get-TestRemoteDomain {
            param([string]$Name, [bool]$Forwarding)
            [pscustomobject]@{ DomainName = $Name; AutoForwardEnabled = $Forwarding }
        }
    }

    It 'needs no exclusions when only the default domain forwards, but still fails and needs a tenant fix' {
        $finding = Get-ExoFinding @((Get-TestRemoteDomain '*' $true))
        $finding | Should -Not -BeNullOrEmpty
        $finding.Result | Should -Be 'Fail'
        $finding.RequiresAction | Should -Be 'FIX_TENANT'
        $finding.ConfigAction | Should -Be 'FIX_TENANT'
        $finding.DetectedExclusionValues.Count | Should -Be 0
        $finding.YamlBlock | Should -BeNullOrEmpty
        $finding.RootCause | Should -Match 'cannot be allow-listed'
        $finding.RootCause | Should -Match '\*'
        ($finding.Recommendations -join ' ') | Should -Match 'No exclusions are needed'
    }

    It 'offers only the other forwarding domains as exclusions and never the default domain' {
        $finding = Get-ExoFinding @(
            (Get-TestRemoteDomain '*' $true)
            (Get-TestRemoteDomain 'contoso.com' $true)
            (Get-TestRemoteDomain 'fabrikam.com' $true)
            (Get-TestRemoteDomain 'blocked.example' $false)
        )
        $finding.Result | Should -Be 'Fail'
        $finding.ConfigAction | Should -Be 'EXCLUDE'
        ($finding.DetectedExclusionValues['AllowedForwardingDomains'] | Sort-Object) -join ',' | Should -Be 'contoso.com,fabrikam.com'
        $finding.YamlBlock | Should -Match 'contoso\.com'
        $finding.YamlBlock | Should -Match 'fabrikam\.com'
        $finding.YamlBlock | Should -Not -Match '(?m)^\s*-\s*"?\*"?\s*$'
        $finding.YamlBlock | Should -Not -Match 'blocked\.example'
        $finding.RootCause | Should -Match 'must be fixed in the tenant'
        $finding.RootCause | Should -Match 'contoso\.com'
    }

    It 'offers the forwarding domains as exclusions when the default domain is already disabled' {
        $finding = Get-ExoFinding @((Get-TestRemoteDomain '*' $false), (Get-TestRemoteDomain 'contoso.com' $true))
        $finding.Result | Should -Be 'Fail'
        $finding.ConfigAction | Should -Be 'EXCLUDE'
        $finding.DetectedExclusionValues['AllowedForwardingDomains'] | Should -Be @('contoso.com')
        $finding.RootCause | Should -Not -Match 'must be fixed in the tenant'
    }

    It 'passes when nothing forwards' {
        $finding = Get-ExoFinding @((Get-TestRemoteDomain '*' $false), (Get-TestRemoteDomain 'contoso.com' $false))
        $finding.Result | Should -Be 'Pass'
        $finding.YamlBlock | Should -BeNullOrEmpty
    }

    It 'asks for manual review instead of passing when no remote domain data was collected' {
        $finding = Get-ExoFinding $null
        $finding.Result | Should -Be 'Manual'
    }

    It 'keeps ordinary detectors (no nonExcludable flag) unchanged' {
        $antiPhish = [pscustomobject]@{ EnableTargetedUserProtection = $true; TargetedUsersToProtect = @('Jane;jane@contoso.com') }
        $raw = [pscustomobject]@{ anti_phish_policies = @($antiPhish) }
        $analysis = & (Get-Module ScubaConfigAnalyzerProviderHelper) { param($Raw) Get-ScAProviderAnalysis -ExclusionField SensitiveUsers -Raw $Raw } $raw
        $analysis.Flagged | Should -Contain 'Jane;jane@contoso.com'
        @($analysis.Blocking).Count | Should -Be 0
        $analysis.ExclusionValues['SensitiveUsers'] | Should -Contain 'Jane;jane@contoso.com'
    }

    It 'applies the same rules when analyzing an existing results file' -ForEach @(
        @{ Name = 'default only'; Domains = @(@{ n = '*'; f = $true }); Action = 'FIX_TENANT'; Values = @() }
        @{ Name = 'default and others'; Domains = @(@{ n = '*'; f = $true }, @{ n = 'contoso.com'; f = $true }); Action = 'EXCLUDE'; Values = @('contoso.com') }
    ) {
        $resultsFile = Join-Path $TestDrive "results-$($Name -replace ' ', '-').json"
        @{
            MetaData = @{ DisplayName = 'Test'; DomainName = 'test.onmicrosoft.com'; TenantId = 'tid' }
            Summary  = @{ Exo = @{ Passes = 0; Failures = 1; Warnings = 0; Errors = 0; Manual = 0 } }
            Results  = @{ Exo = @(@{ GroupName = 'Forwarding'; Controls = @(@{
                            'Control ID' = 'MS.EXO.1.1v2'; Requirement = 'Automatic forwarding to external domains SHALL be disabled.'
                            Result = 'Fail'; Details = 'x'
                        }) }) }
            Raw      = @{
                remote_domains = @($Domains | ForEach-Object { @{ DomainName = $_.n; AutoForwardEnabled = $_.f } })
                scuba_config   = @{}
            }
        } | ConvertTo-Json -Depth 10 | Set-Content $resultsFile -Encoding utf8
        $analysis = Invoke-ScubaConfigAnalysis -ResultsPath $resultsFile -Product exo @paths
        $finding = @($analysis.Findings | Where-Object ControlId -EQ 'MS.EXO.1.1v2')[0]
        $finding.Result | Should -Be 'Fail'
        $finding.ConfigAction | Should -Be $Action
        @($finding.DetectedExclusionValues['AllowedForwardingDomains']) | Should -Be $Values
        $finding.YamlBlock | Should -Not -Match '(?m)^\s*-\s*"?\*"?\s*(#.*)?$'
        if ($Values.Count -eq 0) { $finding.YamlBlock | Should -BeNullOrEmpty }
    }

    It 'documents the default-domain detector as JSON metadata, not a code path' {
        $control = Get-Content $paths.AnalyzerControlPath -Raw | ConvertFrom-Json
        $detectors = @($control.exclusionDefinitions.AllowedForwardingDomains.analysis.detectors)
        $blockingDetector = @($detectors | Where-Object { $_.nonExcludable })
        $blockingDetector.Count | Should -Be 1
        ($blockingDetector[0].flagWhen.allOf | Where-Object { $_.path -eq 'DomainName' }).equals | Should -Be '*'
        $exclusionDetector = @($detectors | Where-Object { -not $_.nonExcludable })
        ($exclusionDetector[0].flagWhen.allOf | Where-Object { $_.path -eq 'DomainName' }).notEquals | Should -Be '*'
    }
}
