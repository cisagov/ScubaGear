$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
$BaselinePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/baselines"
$MarkdownCases = @(
    @{Product = "aad"; MarkdownFileName = "aad.md"; BaselinePath = $BaselinePath}
    @{Product = "securitysuite"; MarkdownFileName = "securitysuite.md"; BaselinePath = $BaselinePath}
    @{Product = "exo"; MarkdownFileName = "exo.md"; BaselinePath = $BaselinePath}
    @{Product = "powerbi"; MarkdownFileName = "powerbi.md"; BaselinePath = $BaselinePath}
    @{Product = "powerplatform"; MarkdownFileName = "powerplatform.md"; BaselinePath = $BaselinePath}
    @{Product = "sharepoint"; MarkdownFileName = "sharepoint.md"; BaselinePath = $BaselinePath}
    @{Product = "teams"; MarkdownFileName = "teams.md"; BaselinePath = $BaselinePath}
)
$ImportCases = @(
    @{Product = "aad"; GroupCount = 9; PolicyCount = 34; BaselinePath = $BaselinePath}
    @{Product = "securitysuite"; GroupCount = 8; PolicyCount = 24; BaselinePath = $BaselinePath}
    @{Product = "exo"; GroupCount = 8; PolicyCount = 12; BaselinePath = $BaselinePath}
    @{Product = "powerbi"; GroupCount = 7; PolicyCount = 8; BaselinePath = $BaselinePath}
    @{Product = "powerplatform"; GroupCount = 6; PolicyCount = 9; BaselinePath = $BaselinePath}
    @{Product = "sharepoint"; GroupCount = 3; PolicyCount = 8; BaselinePath = $BaselinePath}
    @{Product = "teams"; GroupCount = 4; PolicyCount = 14; BaselinePath = $BaselinePath}
)
Import-Module $CreateReportModulePath -Force

InModuleScope CreateReport -Parameters @{MarkdownCases = $MarkdownCases; ImportCases = $ImportCases} {
    param($MarkdownCases, $ImportCases)

    Describe -tag "Markdown" -name 'Check Secure Baseline Markdown document exists for <Product>' -ForEach $MarkdownCases {
        It "Markdown file exists for <Product>" {
            $MarkdownFilePath = Join-Path -Path $BaselinePath -ChildPath $MarkdownFileName
            Test-Path -Path $MarkdownFilePath | Should -BeTrue -Because "Current Location: $(Get-Location) File: $MarkdownFilePath "
        }
        It "Import of markdown for <Product> does not throw expection" {
            {Import-SecureBaseline -ProductNames $Product -BaselinePath $BaselinePath} |
            Should -Not -Throw -Because "expect successful parse of secure baseline markdown of $Product"
        }
    }
    Describe -tag "Markdown" -name 'Import secure baseline <Product>' -ForEach $ImportCases {
        BeforeEach{
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Baseline', Justification = 'Variable is used in another scope')]
            $Baselines = Import-SecureBaseline -ProductNames $Product -BaselinePath $BaselinePath
        }
        It "Validate markdown group count for <Product>" {
            {$Baselines.$Product} | Should -Not -Throw
            $Groups = $Baselines.$Product
            $Groups.Length | Should -BeExactly $GroupCount -Because "known count of groups for $Product"

            $NumberOfPolicies = 0
            $GroupNumbers = @()
            foreach ($Group in $Groups){
                $Group.GroupName | Should -Not -BeNullOrEmpty
                [int]$Group.GroupNumber | Should -BeGreaterThan 0
                $GroupNumbers += [int]$Group.GroupNumber
                $Controls = $Group.Controls
                $NumberOfPolicies += $Controls.Length

                foreach ($Control in $Controls){
                    $Control.Id -Match  "^MS\.$($Product.ToUpper())\.\d{1,}\.\d{1,}v\d{1,}$" | Should -BeTrue
                    $Control.Value | Should -Not -BeNullOrEmpty -Because "$($Control.Id) requires a valid description."
                    $Control.Deleted.GetType() -Eq [bool]| Should -BeTrue -Because "Type should be boolean."
                }
            }

            $GroupNumbers | Select-Object -Unique | Should -HaveCount $GroupCount
            $NumberOfPolicies | Should -BeExactly $PolicyCount -Because "known count of policies for $Product"
        }
    }
}