$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
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
    Describe -tag "Markdown" -name 'Fail import secure baseline (bad path)' {
        It "Fails on bad baseline path" {
            {Import-SecureBaseline -ProductNames "aad" -BaselinePath "garbage path"} |
            Should -Throw
        }
    }
    Describe -tag "Markdown" -name 'Check error handling.' {
        BeforeAll{
            Mock -ModuleName CreateReport -CommandName Write-Error {}
        }
        It "Invoke error messages on parsing errors" {
            {
                Import-SecureBaseline -ProductNames "aad" -BaselinePath "./Testing/Unit/PowerShell/CreateReport/CreateReportStubs"
                Should -Invoke -CommandName Write-Error -Exactly -Times 2 -Because "Except errors on parsing"
            } | Should -Throw

        }
    }
}