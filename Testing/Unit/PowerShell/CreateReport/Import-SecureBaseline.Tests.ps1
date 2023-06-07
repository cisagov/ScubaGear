$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath -Force

InModuleScope CreateReport {

    Describe -tag "Markdown" -name 'Check Secure Baseline Markdown document for <Product>' -ForEach @(
        @{Product = "aad"; MarkdownFilePath = "baselines/aad.md"}
        @{Product = "defender"; MarkdownFilePath = "baselines/defender.md"}
        @{Product = "exo"; MarkdownFilePath = "baselines/exo.md"}
        @{Product = "onedrive"; MarkdownFilePath = "baselines/onedrive.md"}
        @{Product = "powerbi"; MarkdownFilePath = "baselines/powerbi.md"}
        @{Product = "powerplatform"; MarkdownFilePath = "baselines/powerplatform.md"}
        @{Product = "sharepoint"; MarkdownFilePath = "baselines/sharepoint.md"}
        @{Product = "teams"; MarkdownFilePath = "baselines/teams.md"}
    ){
        It "Markdown file exists for <Product>" {
            Test-Path -Path $MarkdownFilePath | Should -BeTrue -Because "Current Location: $(Get-Location) File: $MarkdownFilePath "
        }
    }
    Describe -tag "Markdown" -name 'Fail import secure baseline ' {
        It "Fails on bad baseline path" {
            {Import-SecureBaseline -BaselinePath "garbage path"} |
            Should -Throw
        }
    }
    Describe -tag "Markdown" -name 'Import secure baseline' {
        BeforeAll{
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Baseline', Justification = 'Variable is used in another scope')]
            $Baselines = Import-SecureBaseline -BaselinePath "./baselines/"
        }
        It "Validate import of markdown for all products" {
            $Baselines.GetType().Name -Eq [hashtable] | Should -BeTrue
            $Baselines.Count | Should -BeExactly 8 -Because "Markdown expected for all products."
        }
        It "Validate markdown group count for <Product>" -ForEach @(
            @{Product = "aad"; GroupCount = 18; PolicyCount = 33}
            @{Product = "defender"; GroupCount = 10; PolicyCount = 46}
            @{Product = "exo"; GroupCount = 17; PolicyCount = 39}
            @{Product = "onedrive"; GroupCount = 7; PolicyCount = 8}
            @{Product = "powerbi"; GroupCount = 10; PolicyCount = 12}
            @{Product = "powerplatform"; GroupCount = 4; PolicyCount = 8}
            @{Product = "sharepoint"; GroupCount = 5; PolicyCount = 10}
            @{Product = "teams"; GroupCount = 13; PolicyCount = 28}
        ){
            {$Baselines.$Product} | Should -Not -Throw
            $Groups = $Baselines.$Product
            $Groups.Length | Should -BeExactly $GroupCount

            $NumberOfPolicies = 0
            foreach ($Group in $Groups){
                $Group.GroupName | Should -Not -BeNullOrEmpty
                [int]$Group.GroupNumber | Should -BeLessOrEqual $GroupCount
                $Controls = $Group.Controls
                $NumberOfPolicies += $Controls.Length

                foreach ($Control in $Controls){
                    $Control.Id -Match  "^MS\.$($Product.ToUpper())\.\d{1,}\.\d{1,}v\d{1,}$" | Should -BeTrue
                    $Control.Value -Match "^.*\.$" | Should -BeTrue -Because "$Control.Id does not end with period."
                    #$Control.Value -Match '^(.+)(SHALL|SHOULD|MAY){1,1}(.+\.)$'
                    #@("SHALL", "SHOULD", "MAY") -Contains $Matches.2 | Should -BeTrue -Because "$($Control.Id) must contain valid criticality but has $($Matches.2)"
                    #@("SHALL", "SHOULD", "MAY") -Contains $Control.Criticality | Should -BeTrue
                    $Control.Deleted.GetType() -Eq [bool]| Should -BeTrue -Because "Type should be boolean."
                }
            }

            $NumberOfPolicies | Should -BeExactly $PolicyCount
        }
    }
}