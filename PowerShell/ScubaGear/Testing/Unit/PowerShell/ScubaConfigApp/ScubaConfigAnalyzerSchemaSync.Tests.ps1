# Drift guard for the Config Analyzer (Start-SCuBAConfigAnalyzer).
#
# The analyzer's per-control validation rules live in
#   PowerShell/ScubaGear/schemas/ScubaGearResultsBaselineSchema.json
# and are authored in parallel with the authoritative Rego policies in
#   PowerShell/ScubaGear/Rego/*.rego
#
# This test enforces the STRUCTURAL half of that contract: every control id the analyzer
# models must correspond to a real Rego PolicyId. It catches renamed, removed, or mistyped
# ids - the most common way the JSON goes stale. It cannot detect semantic drift (a changed
# condition value), which is covered by the maintenance checklist in
#   docs/misc/scubaconfiganalyzer-schema-maintenance.md
#
Describe -tag "Analyzer" -name 'ScubaConfigAnalyzer baseline schema stays in sync with Rego' {
    BeforeDiscovery {
        $scubaGearRoot   = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $baselineSchema  = Join-Path $scubaGearRoot 'schemas\ScubaGearResultsBaselineSchema.json'
        $regoDir         = Join-Path $scubaGearRoot 'Rego'

        # All PolicyIds ScubaGear's Rego actually emits (union across every product's rego).
        $regoPolicyIds = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase)
        foreach ($rego in Get-ChildItem -Path $regoDir -Filter '*.rego' -File) {
            foreach ($m in [regex]::Matches((Get-Content $rego.FullName -Raw), '"PolicyId":\s*"([^"]+)"')) {
                [void]$regoPolicyIds.Add($m.Groups[1].Value)
            }
        }

        # Every control the analyzer models, as hashtables so Pester -ForEach exposes
        # each key (Product, Id) as a variable inside the It block.
        $schema = Get-Content $baselineSchema -Raw | ConvertFrom-Json
        $analyzerControls = foreach ($prod in $schema.baselineValidations.PSObject.Properties) {
            foreach ($control in @($prod.Value)) {
                if ($control.id) { @{ Product = $prod.Name; Id = [string]$control.id } }
            }
        }
        $analyzerControls = @($analyzerControls)
    }

    BeforeAll {
        $scubaGearRoot   = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $baselineSchema  = Join-Path $scubaGearRoot 'schemas\ScubaGearResultsBaselineSchema.json'
        $regoDir         = Join-Path $scubaGearRoot 'Rego'

        $regoPolicyIds = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase)
        foreach ($rego in Get-ChildItem -Path $regoDir -Filter '*.rego' -File) {
            foreach ($m in [regex]::Matches((Get-Content $rego.FullName -Raw), '"PolicyId":\s*"([^"]+)"')) {
                [void]$regoPolicyIds.Add($m.Groups[1].Value)
            }
        }

        $schema = Get-Content $baselineSchema -Raw | ConvertFrom-Json
        $analyzerControls = foreach ($prod in $schema.baselineValidations.PSObject.Properties) {
            foreach ($control in @($prod.Value)) {
                if ($control.id) { [pscustomobject]@{ Product = $prod.Name; Id = [string]$control.id } }
            }
        }
        $analyzerControls = @($analyzerControls)
    }

    Context 'Baseline schema structural integrity' {
        It 'is valid JSON with a baselineValidations object' {
            $schema.baselineValidations | Should -Not -BeNullOrEmpty
        }

        It 'models at least one control' {
            @($analyzerControls).Count | Should -BeGreaterThan 0
        }

        It 'has well-formed control ids (MS.<PRODUCT>.<group>.<item>v<version>)' {
            $malformed = @($analyzerControls | Where-Object { $_.Id -notmatch '^MS\.[A-Z]+\.\d+\.\d+v\d+$' })
            $malformed.Id -join ', ' | Should -BeNullOrEmpty `
                -Because 'every analyzer control id must follow the MS.PRODUCT.g.iVv format'
        }

        It 'has unique control ids' {
            $dupes = @($analyzerControls | Group-Object Id | Where-Object { $_.Count -gt 1 })
            ($dupes | ForEach-Object { $_.Name }) -join ', ' | Should -BeNullOrEmpty `
                -Because 'a control id must appear at most once in the baseline schema'
        }
    }

    Context 'Every analyzer control maps to a real Rego PolicyId' {
        It "<Id> (<Product>) exists as a Rego PolicyId" -ForEach $analyzerControls {
            $regoPolicyIds.Contains($Id) | Should -BeTrue -Because `
                "the analyzer references '$Id' but no Rego rule emits that PolicyId - the baseline schema is out of sync with the Rego (renamed, removed, or mistyped id)"
        }
    }

    Context 'Coverage report (informational - never fails CI)' {
        It 'reports Rego PolicyIds the analyzer does not yet model' {
            $modeled = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase)
            foreach ($c in $analyzerControls) { [void]$modeled.Add($c.Id) }

            # Only report products the analyzer already covers; empty products are placeholders.
            $coveredPrefixes = @($analyzerControls | ForEach-Object { ($_.Id -split '\.')[1] } | Sort-Object -Unique)
            $unmodeled = @($regoPolicyIds | Where-Object {
                    $prefix = ($_ -split '\.')[1]
                    $coveredPrefixes -contains $prefix -and -not $modeled.Contains($_)
                } | Sort-Object)

            Write-Host "[Config Analyzer coverage] modeled $(@($analyzerControls).Count) control(s); $(@($unmodeled).Count) Rego policy(ies) in covered products are not yet modeled:"
            foreach ($id in $unmodeled) { Write-Host "  - $id" }

            # Informational only: partial coverage is intentional.
            $true | Should -BeTrue
        }
    }
}
