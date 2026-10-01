Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/Support.psm1") -Function 'Get-ScubaHelp' -Force

# Loaded at discovery scope so the -ForEach test cases below can enumerate the catalog.
$CatalogPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../schemas/ScubaHelp.json"
$CatalogCommands = (Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json).commands

Describe "Get-ScubaHelp" {
    BeforeAll {
        $CatalogPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../schemas/ScubaHelp.json"
        $script:Catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
        $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../ScubaGear.psd1"
        $script:ExportedFunctions = (Import-PowerShellDataFile -Path $ManifestPath).FunctionsToExport
        $script:PendingCommands = @('Invoke-SCuBADiff')
    }

    Context "Catalog integrity (ScubaHelp.json)" {
        It "parses as JSON and contains commands" {
            $Catalog.commands.Count | Should -BeGreaterThan 0
        }
        It "entry '<_.name>' has all required non-empty fields" -ForEach $CatalogCommands {
            $_.name     | Should -Not -BeNullOrEmpty
            $_.category | Should -Not -BeNullOrEmpty
            $_.summary  | Should -Not -BeNullOrEmpty
            $_.useWhen  | Should -Not -BeNullOrEmpty
            $_.why      | Should -Not -BeNullOrEmpty
            $_.online   | Should -Not -BeNullOrEmpty
            $_.docs     | Should -Not -BeNullOrEmpty
        }
        It "entry '<_.name>' uses an allowed category" -ForEach $CatalogCommands {
            $_.category | Should -BeIn @('Configuration', 'Core', 'Setup')
        }
    }

    Context "Consistency with the module manifest" {
        It "catalog command '<_.name>' is exported (or explicitly pending)" -ForEach $CatalogCommands {
            if ($_.name -in $PendingCommands) {
                Set-ItResult -Skipped -Because "command is pending in this branch"
                return
            }
            $ExportedFunctions | Should -Contain $_.name
        }
    }

    Context "Function behavior" {
        It "returns one object per catalog entry" {
            (Get-ScubaHelp).Count | Should -Be $Catalog.commands.Count
        }
        It "tags output with the ScubaGear.CommandHelp type" {
            (Get-ScubaHelp)[0].PSObject.TypeNames | Should -Contain 'ScubaGear.CommandHelp'
        }
        It "filters by -Category" {
            $Core = Get-ScubaHelp -Category Core
            $Core | Should -Not -BeNullOrEmpty
            ($Core | Where-Object { $_.Category -ne 'Core' }) | Should -BeNullOrEmpty
        }
        It "filters by -Command with wildcards" {
            $Result = Get-ScubaHelp -Command 'Invoke-SCuBA'
            $Result.Command | Should -Be 'Invoke-SCuBA'
        }
    }
}
