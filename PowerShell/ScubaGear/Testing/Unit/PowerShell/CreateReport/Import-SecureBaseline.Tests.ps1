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
        BeforeAll{
            Mock -ModuleName CreateReport -CommandName Write-Error {}
        }
        It "Markdown file exists for <Product>" {
            Test-Path -Path $MarkdownFilePath | Should -BeTrue -Because "Current Location: $(Get-Location) File: $MarkdownFilePath "
        }
        It "Import of markdown for <Product> does not throw expection" {
            {Import-SecureBaseline -ProductNames $Product -BaselinePath "./baselines/"} |
            Should -Not -Throw -Because "expect successful parse of secure baseline markdown of $Product"
        }
        It "Check markdown parsing does not throw any errors" {
            Import-SecureBaseline -ProductNames $Product -BaselinePath "./baselines/"
            Should -Invoke -CommandName Write-Error -Exactly -Times 0 -Because "do not expect parsing errors on markdown document"
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
            Mock -ModuleName CreateReport -CommandName Write-Warning {}
        }
        It "Check not throw an exception with malformed baseline" {
            {
                Import-SecureBaseline -ProductNames "aad" -BaselinePath "./Testing/Unit/PowerShell/CreateReport/CreateReportStubs"
            } | Should -Not -Throw
        }
        It "Check expected error count" {
            Import-SecureBaseline -ProductNames "aad" -BaselinePath "./Testing/Unit/PowerShell/CreateReport/CreateReportStubs"
            Should -Invoke -CommandName Write-Error -Exactly -Times 1 -Because "Except 1 error on parsing"
            Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Because "Except 1 warning on parsing"
        }
        It "Check MS.AAD.1.1v1 for malformed" {
            $Output = Import-SecureBaseline -ProductNames "aad" -BaselinePath "./Testing/Unit/PowerShell/CreateReport/CreateReportStubs"
            $Output.aad.Controls[0].MalformedDescription | Should -BeTrue -Because "MS.AAD.1.1v1 policy description does not start on line immediately after policy id."
            $Output.aad.Controls[0].Value | Should -Be "Error - The baseline policy text is malformed. Description should start immediately after Policy Id."
        }
        It "Check MS.AAD.2.1v1 for malformed" {
            $Output = Import-SecureBaseline -ProductNames "aad" -BaselinePath "./Testing/Unit/PowerShell/CreateReport/CreateReportStubs"
            $Output.aad.Controls[1].MalformedDescription | Should -BeFalse -Because "Only warning for MS.AAD.2.1v1 policy description with to many lines."
        }
    }
}