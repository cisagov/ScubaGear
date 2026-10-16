$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath -Force

InModuleScope CreateReport {

    Describe -tag "Markdown" -name 'Check Secure Baseline Markdown document exists for <Product>' -ForEach @(
        @{Product = "aad"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\aad.md" -Resolve }
        @{Product = "securitysuite"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\securitysuite.md" -Resolve}
        @{Product = "exo"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\exo.md" -Resolve}
        @{Product = "powerbi"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\powerbi.md" -Resolve}
        @{Product = "powerplatform"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\powerplatform.md" -Resolve}
        @{Product = "sharepoint"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\sharepoint.md" -Resolve}
        @{Product = "teams"; MarkdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\teams.md" -Resolve}
    ){
        BeforeAll{
            Mock -ModuleName CreateReport -CommandName Write-Error {}
        }
        It "Markdown file exists for <Product>" {
            Test-Path -Path $MarkdownFilePath | Should -BeTrue
        }
        It "Import of markdown for <Product> does not throw expection" {
            {Import-SecureBaseline -ProductNames $Product -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines" -Resolve)} |
            Should -Not -Throw -Because "expect successful parse of secure baseline markdown of $Product"
        }
        It "Check markdown parsing does not throw any errors" {
            Import-SecureBaseline -ProductNames $Product -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines" -Resolve)
            Should -Invoke -CommandName Write-Error -Exactly -Times 0 -Because "do not expect parsing errors on markdown document"
        }
        It "Policy descriptions exclude following badge markdown for <Product>" {
            $Output = Import-SecureBaseline -ProductNames $Product -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines" -Resolve)
            $WithBadges = foreach ($Group in $Output.$Product) {
                foreach ($Control in $Group.Controls) {
                    if ($Control.Value -match '\[!\[') {
                        $Control.Id
                    }
                }
            }
            $WithBadges | Should -BeNullOrEmpty -Because "a description ending in a period inside quotes must not continue into the indicator badges"
        }
    }
    Describe -tag "Markdown" -name 'Descriptions that end with a period inside quotes' {
        BeforeAll {
            $BaselinePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines" -Resolve
            $Parsed = Import-SecureBaseline -ProductNames @('aad', 'sharepoint', 'teams') -BaselinePath $BaselinePath
        }
        It 'Keeps the baseline text for <Id>' -ForEach @(
            @{
                Product = 'sharepoint'
                Id = 'MS.SHAREPOINT.1.1v1'
                Expected = 'External sharing for SharePoint SHALL be limited to "Existing guests" or "Only people in your organization."'
            }
            @{
                Product = 'sharepoint'
                Id = 'MS.SHAREPOINT.1.2v1'
                Expected = 'External sharing for OneDrive SHALL be limited to "Existing guests" or "Only people in your organization."'
            }
            @{
                Product = 'sharepoint'
                Id = 'MS.SHAREPOINT.2.1v1'
                Expected = 'File and folder default sharing scope SHALL be set to "Specific people (only the people the user specifies)."'
            }
            @{
                Product = 'aad'
                Id = 'MS.AAD.3.4v1'
                Expected = 'The "Authentication methods manage migration" feature SHALL be set to "Migration complete."'
            }
            @{
                Product = 'teams'
                Id = 'MS.TEAMS.1.7v2'
                Expected = '"Record an event" SHOULD NOT be set to "Always record."'
            }
        ) {
            $Control = foreach ($Group in $Parsed.$Product) {
                foreach ($Item in $Group.Controls) {
                    if ($Item.Id -eq $Id) { $Item }
                }
            }
            $Control.Value | Should -Be $Expected
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
                Import-SecureBaseline -ProductNames "aad" -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs" -Resolve)
            } | Should -Not -Throw
        }
        It "Check expected error count" {
            Import-SecureBaseline -ProductNames "aad" -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs" -Resolve)
            Should -Invoke -CommandName Write-Error -Exactly -Times 1 -Because "Except 1 error on parsing"
            Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Because "Except 1 warning on parsing"
        }
        It "Check MS.AAD.1.1v1 for malformed" {
            $Output = Import-SecureBaseline -ProductNames "aad" -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs" -Resolve)
            $Output.aad.Controls[0].MalformedDescription | Should -BeTrue -Because "MS.AAD.1.1v1 policy description does not start on line immediately after policy id."
            $Output.aad.Controls[0].Value | Should -Be "Error - The baseline policy text is malformed. Description should start immediately after Policy Id."
        }
        It "Check MS.AAD.2.1v1 for malformed" {
            $Output = Import-SecureBaseline -ProductNames "aad" -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs" -Resolve)
            $Output.aad.Controls[1].MalformedDescription | Should -BeFalse -Because "Only warning for MS.AAD.2.1v1 policy description with to many lines."
        }
    }
}
