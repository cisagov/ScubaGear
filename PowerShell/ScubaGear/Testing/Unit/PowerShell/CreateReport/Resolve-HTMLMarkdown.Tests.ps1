$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath

InModuleScope CreateReport {
    Describe -Tag "Resolve-HTMLMarkdown" -name "Parameter error handling" {
        It "Empty original string" {
            {Resolve-HTMLMarkdown -OriginalString "" -HTMLReplace "italic"} |
                Should -Throw -Because "Invalid OriginalString parameter"
        }
        It "Empty html replacement string" {
            {Resolve-HTMLMarkdown -OriginalString "A valid string" -HTMLReplace ""} |
                Should -Throw -Because "Invalid HTMLReplace parameter"
        }
        It "Null original string" {
            {Resolve-HTMLMarkdown -OriginalString $null -HTMLReplace "italic"} |
                Should -Throw -Because "Invalid OriginalString parameter"
        }
        It "Null html replacement string" {
            {Resolve-HTMLMarkdown -OriginalString "A valid string" -HTMLReplace $null} |
                Should -Throw -Because "Invalid HTMLReplace parameter"
        }
        It "Bad html replacement string" {
            {Resolve-HTMLMarkdown -OriginalString "A valid string" -HTMLReplace "underline"} |
                Should -Throw -ExceptionType ArgumentException
        }
    }

    Describe -tag "Resolve-HTMLMarkdown" -name 'Test resolve HTML Markdown in baseline descriptions' {
        It "Test Valid html markdown resolution: <OriginalString> <HTMLReplace>" -ForEach @(
            @{ OriginalString = "__A test string.__"; HTMLReplace = "italic"; HTMLTranslation = "<i>(.*?)</i>"},
            @{ OriginalString = "**A test string.**"; HTMLReplace = "bold"; HTMLTranslation = "<b>(.*?)</b>"}
        ){
            $ResolvedString = Resolve-HTMLMarkdown -OriginalString $OriginalString -HTMLReplace $HTMLReplace
            $ResolvedString -Match $HTMLTranslation | Should -BeTrue
        }
    }
    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
        }
    }
