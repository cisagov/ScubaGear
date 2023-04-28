$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath

InModuleScope CreateReport {

    Describe -tag "Markdown" -name 'Check Secure Baseline Markdown document for <Product>' -ForEach @(
        @{Product = "aad"; MarkdownFilePath = "baselines/aad.md"}
        @{Product = "defender"; MarkdownFilePath = "baselines/defender.md"}
        @{Product = "exchange"; MarkdownFilePath = "baselines/exchange.md"}
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
            $Baselines.Length | Should -BeExactly 8
        }
        It "Validate markdown group count for <Product>" -ForEach @(
            @{Product = "aad"; GroupCount = 0; PolicyCount = 0}
            @{Product = "defender"; GroupCount = 0; PolicyCount = 0}
            @{Product = "exchange"; GroupCount = 0; PolicyCount = 0}
            @{Product = "onedrive"; GroupCount = 0; PolicyCount = 0}
            @{Product = "powerbi"; GroupCount = 0; PolicyCount = 0}
            @{Product = "powerplatform"; GroupCount = 0; PolicyCount = 0}
            @{Product = "sharepoint"; GroupCount = 0; PolicyCount = 0}
            @{Product = "teams"; GroupCount = 13; PolicyCount = 28}
        ){
            {$Baselines.$Product} | Should -Not -Throw
            $Groups = $Baselines.$Product
            Write-Host "Baseline: $($Baselines | ConvertTo-Json -Depth 4)"
            $Groups.Length | Should -BeExactly $GroupCount

            #Write-Host "Baseline: $($Baselines | ConvertTo-Json -Depth 4)"

            $NumberOfPolicies = 0
            foreach ($Group in $Groups){
                $Group.GroupName | Should -Not -BeNullOrEmpty
                [int]$Group.GroupNumber | Should -BeLessOrEqual $GroupCount
                $Controls = $Group.Controls
                $NumberOfPolicies += $Controls.Length

                foreach ($Control in $Controls){
                    $Control.Id -Match  "^MS\.$($Product.ToUpper())\.\d{1,}\.\d{1,}v\d{1,}$" | Should -BeTrue
                    $Control.Value -Match "^.*\.$" | Should -BeTrue
                    $Control.Deleted | Should -Not -BeNullOrEmpty
                }
            }

            $NumberOfPolicies | Should -BeExactly $PolicyCount
        }
    }
}