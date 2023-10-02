$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath -Force

InModuleScope CreateReport {

    Describe -tag "Markdown" -name 'Check Secure Baseline Markdown document exists for <Product>' -ForEach @(
        @{Product = "aad"; MarkdownFilePath = "baselines/aad.md"}
        @{Product = "defender"; MarkdownFilePath = "baselines/defender.md"}
        @{Product = "exo"; MarkdownFilePath = "baselines/exo.md"}
        @{Product = "powerbi"; MarkdownFilePath = "baselines/powerbi.md"}
        @{Product = "powerplatform"; MarkdownFilePath = "baselines/powerplatform.md"}
        @{Product = "sharepoint"; MarkdownFilePath = "baselines/sharepoint.md"}
        @{Product = "teams"; MarkdownFilePath = "baselines/teams.md"}
    ){
        It "Markdown file exists for <Product>" {
            Test-Path -Path $MarkdownFilePath | Should -BeTrue -Because "Current Location: $(Get-Location) File: $MarkdownFilePath "
        }
        It "Import of markdown for <Product> does not throw expection" {
            {Import-SecureBaseline -ProductNames $Product -BaselinePath "./baselines/"} |
            Should -Not -Throw -Because "expect successful parse of secure baseline markdown of $Product"
        }
    }
    Describe -tag "Markdown" -name 'Import secure baseline <Product>' -ForEach @(
        @{Product = "aad"; GroupCount = 8; PolicyCount = 30}
        @{Product = "defender"; GroupCount = 6; PolicyCount = 20}
        @{Product = "exo"; GroupCount = 17; PolicyCount = 37}
        @{Product = "powerbi"; GroupCount = 7; PolicyCount = 8}
        @{Product = "powerplatform"; GroupCount = 5; PolicyCount = 8}
        @{Product = "sharepoint"; GroupCount = 4; PolicyCount = 11}
        @{Product = "teams"; GroupCount = 8; PolicyCount = 21}
    ){
        BeforeEach{
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Baseline', Justification = 'Variable is used in another scope')]
            $Baselines = Import-SecureBaseline -ProductNames $Product -BaselinePath "./baselines/"
        }
        It "Validate markdown group count for <Product>" {
            {$Baselines.$Product} | Should -Not -Throw
            $Groups = $Baselines.$Product
            $Groups.Length | Should -BeExactly $GroupCount -Because "known count of groups for $Product"

            $NumberOfPolicies = 0
            foreach ($Group in $Groups){
                $Group.GroupName | Should -Not -BeNullOrEmpty
                [int]$Group.GroupNumber | Should -BeLessOrEqual $GroupCount
                $Controls = $Group.Controls
                $NumberOfPolicies += $Controls.Length

                foreach ($Control in $Controls){
                    $Control.Id -Match  "^MS\.$($Product.ToUpper())\.\d{1,}\.\d{1,}v\d{1,}$" | Should -BeTrue
                    $Control.Value | Should -Not -BeNullOrEmpty -Because "$($Control.Id) requires a valid description."
                    $Control.Deleted.GetType() -Eq [bool]| Should -BeTrue -Because "Type should be boolean."
                }
            }

            $NumberOfPolicies | Should -BeExactly $PolicyCount -Because "known count of policies for $Product"
        }
    }
}