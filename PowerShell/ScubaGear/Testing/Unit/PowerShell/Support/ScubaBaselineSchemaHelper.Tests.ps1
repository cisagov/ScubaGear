BeforeAll {
    $moduleRoot = Join-Path $PSScriptRoot '..\..\..\..'
    Import-Module (Join-Path $moduleRoot 'Modules\Support\ScubaBaselineSchemaHelper.psm1') -Force
    $baselineDirectory = Join-Path $moduleRoot 'baselines'
    $outputPath = Join-Path $TestDrive 'ScubaBaselines.json'
    Update-ScubaConfigBaselineWithMarkdown -BaselineDirectory $baselineDirectory -BaselineFilePath $outputPath | Out-Null
    $baseline = Get-Content $outputPath -Raw | ConvertFrom-Json
    $script:policies = @($baseline.baselines.PSObject.Properties.Value | ForEach-Object { $_ })
}

Describe 'Baseline markdown extraction' {
    It 'preserves the shared introduction without the product-specific opening paragraph' {
        $baseline.Introduction | Should -Match "^The Cybersecurity and Infrastructure Security Agency's"
        $baseline.Introduction | Should -Match 'The CISA SCuBA SCBs for M365'
        $baseline.Introduction | Should -Match 'For non-federal users'
        $baseline.Introduction | Should -Match 'This document is marked TLP:CLEAR'
        $baseline.Introduction | Should -Not -Match 'Microsoft Entra ID is a cloud-based|# CISA|## License Compliance'
    }

    It 'extracts shared preambles regardless of their opening wording' {
        $fixtureDirectory = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'header-fixture')
        foreach ($opening in @(
            'The Secure Cloud Business Applications (SCuBA) project provides guidance.',
            "The Cybersecurity and Infrastructure Security Agency's (CISA) Secure Cloud Business Applications (SCuBA) project provides guidance."
        )) {
            @"
# Product baseline

Product-specific opening that wraps
onto a second source line.

$opening

The remaining shared paragraph.

## License Compliance and Copyright
License text.
"@ | Set-Content (Join-Path $fixtureDirectory.FullName 'aad.md')
            $header = Get-ScubaBaselineHeaderContent -BaselineDirectory $fixtureDirectory.FullName
            ($header.Introduction -replace "`r`n", "`n") | Should -Be "$opening`n`nThe remaining shared paragraph."
        }
    }

    It 'reports an invalid introduction layout rather than silently generating empty content' {
        $fixtureDirectory = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'invalid-header')
        '# Incomplete document' | Set-Content (Join-Path $fixtureDirectory.FullName 'aad.md')
        { Get-ScubaBaselineHeaderContent -BaselineDirectory $fixtureDirectory.FullName } |
            Should -Throw '*Unable to extract the shared baseline introduction*'
    }

    It 'preserves every policy ID and statement' {
        $sourceIds = @(Get-ChildItem $baselineDirectory -Filter '*.md' | Where-Object Name -ne 'removedpolicies.md' | ForEach-Object {
            [regex]::Matches((Get-Content $_.FullName -Raw), '(?m)^#### (MS\.[A-Z]+\.\d+\.\d+v\d+)\s*$') |
                ForEach-Object { $_.Groups[1].Value }
        })
        $policies.Count | Should -Be 161
        Compare-Object ($sourceIds | Sort-Object) ($policies.id | Sort-Object) | Should -BeNullOrEmpty
        @($policies | Where-Object { [string]::IsNullOrWhiteSpace($_.name) }).Count | Should -Be 0
    }

    It 'serializes all link collections as arrays, including the 22 single resources' {
        @($policies | Where-Object { $_.resources.Count -eq 1 }).Count | Should -Be 22
        foreach ($policy in $policies) {
            foreach ($field in 'resources', 'mitreMapping', 'badges', 'licenseRequirements', 'notes') {
                if ($null -ne $policy.$field) {
                    $policy.$field -is [array] | Should -BeTrue -Because "$($policy.id).$field must be an array"
                }
            }
        }
    }

    It 'does not include appendices or document markings in any implementation' {
        foreach ($policy in $policies) {
            $policy.implementation | Should -Not -Match '(?m)^# Appendix|TLP:CLEAR'
        }
    }

    It 'generates separate appendices for Entra ID, Security Suite and Teams' {
        $baseline.appendices.aad.Count | Should -Be 2
        $baseline.appendices.securitysuite -is [array] | Should -BeTrue
        $baseline.appendices.securitysuite.Count | Should -Be 1
        $baseline.appendices.teams.Count | Should -Be 2
        @($baseline.appendices.PSObject.Properties).Count | Should -Be 3
        $baseline.appendices.aad[0].name | Should -Be 'Appendix A: Microsoft Entra ID hybrid Guidance'
        $baseline.appendices.aad[1].name | Should -Be 'Appendix B: Cross-tenant Access Guidance'
        $baseline.appendices.securitysuite[0].anchor | Should -Be '#appendix-a-adding-users-to-the-preset-security-policies'
    }

    It 'preserves every appendix body in source order without footer markings' {
        foreach ($product in $baseline.appendices.PSObject.Properties) {
            $source = Get-Content (Join-Path $baselineDirectory "$($product.Name).md") -Raw -Encoding UTF8
            $expected = [regex]::Matches($source, '(?ms)^# (Appendix[^\r\n]*)\r?\n(.*?)(?=^# |\z)')
            $product.Value.Count | Should -Be $expected.Count
            for ($i = 0; $i -lt $expected.Count; $i++) {
                $body = $expected[$i].Groups[2].Value -replace '(?m)^\*\*`TLP:CLEAR`\*\*\s*$', ''
                $body = $body -replace [char]0x2019, "'" -replace [char]0x201C, '"' -replace [char]0x201D, '"'
                $body = $body -replace [char]0x2013, '-' -replace [char]0x2014, '--'
                $product.Value[$i].content -replace "`r`n", "`n" | Should -BeExactly ($body.Trim() -replace "`r`n", "`n")
                $product.Value[$i].content | Should -Not -Match 'TLP:CLEAR'
            }
        }
        $baseline.appendices.teams[1].content | Should -Match '#### Legacy MS.TEAMS.5.3v1 Instructions'
    }

    It 'applies product filtering to appendix output as well as policies' {
        $filteredPath = Join-Path $TestDrive 'filtered.json'
        Update-ScubaConfigBaselineWithMarkdown -BaselineDirectory $baselineDirectory -BaselineFilePath $filteredPath -ProductFilter @('aad', 'exo') | Out-Null
        $filtered = Get-Content $filteredPath -Raw | ConvertFrom-Json
        @($filtered.appendices.PSObject.Properties.Name) | Should -Be @('aad')
        @($filtered.baselines.PSObject.Properties.Name) | Should -Be @('aad', 'exo')
    }

    It 'keeps the optional instructions through step 12 for <id>' -ForEach @(
        @{ id = 'MS.TEAMS.5.1v2' }
        @{ id = 'MS.TEAMS.5.2v2' }
        @{ id = 'MS.TEAMS.5.3v2' }
    ) {
        $implementation = ($policies | Where-Object id -eq $id).implementation
        $implementation | Should -Match '##### Optional:'
        $implementation | Should -Match '(?m)^7\. Close'
        $implementation | Should -Match '(?m)^12\. Repeat steps 8 to 11'
        $implementation | Should -Not -Match '#### MS\.TEAMS'
    }

    It 'preserves the wrapped Security Suite statement' {
        ($policies | Where-Object id -eq 'MS.SECURITYSUITE.3.5v1').name |
            Should -Be 'The DLP policy SHOULD include an action to block access to sensitive information by restricted applications and unwanted Bluetooth applications.'
    }

    It 'preserves all 91 policy notes and their nested text' {
        @($policies | ForEach-Object { $_.notes } | Where-Object { $_ }).Count | Should -Be 91
        ($policies | Where-Object id -eq 'MS.SECURITYSUITE.3.5v1').notes[0] |
            Should -Match 'This action can only be included if at least one device is onboarded'
    }

    It 'retains the Power BI implementation blockquote' {
        ($policies | Where-Object id -eq 'MS.POWERBI.3.1v1').implementation |
            Should -Match '> Note:\r?\n> You may need to make a specific security group'
    }

    It 'extracts prose licensing for Security Suite sections 1 and 7' {
        $licensed = @($policies | Where-Object { $_.id -match '^MS\.SECURITYSUITE\.(1|7)\.' })
        $licensed.Count | Should -BeGreaterThan 0
        foreach ($policy in $licensed) {
            $policy.licenseRequirements[0] | Should -Match 'Defender for Office 365 Plan 1 or 2'
            $policy.licenseRequirements[0] | Should -Match 'E5 and G5'
        }
    }

    It 'preserves fenced code for rendering as code rather than markdown' {
        ($policies | Where-Object id -eq 'MS.AAD.6.1v1').implementation | Should -Match '```powershell'
    }

    It 'is deterministic when regenerating the same file' {
        $first = Get-Content $outputPath -Raw
        Update-ScubaConfigBaselineWithMarkdown -BaselineDirectory $baselineDirectory -BaselineFilePath $outputPath | Out-Null
        Get-Content $outputPath -Raw | Should -BeExactly $first
    }
}
