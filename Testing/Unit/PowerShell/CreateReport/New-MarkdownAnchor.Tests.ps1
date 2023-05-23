$CreateReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1"
Import-Module $CreateReportModulePath

InModuleScope CreateReport {
    Describe -Tag "Markdown" -name "Parameter error handling" {
        It "Empty group number" {
            {New-MarkdownAnchor -GroupNumber "" -GroupName "A valid name"} |
                Should -Throw -Because "Invalid GroupNumber parameter"
        }
        It "Empty group name" {
            {New-MarkdownAnchor -GroupNumber "1" -GroupName ""} |
                Should -Throw -Because "Invalid GroupName parameter"
        }
        It "Null group number" {
            {New-MarkdownAnchor -GroupNumber $null -GroupName "A valid name"} |
                Should -Throw -Because "Invalid GroupNumber parameter"
        }
        It "Null group name" {
            {New-MarkdownAnchor -GroupNumber "1" -GroupName $null} |
                Should -Throw -Because "Invalid GroupName parameter"
        }
        It "Bad group number" {
            {New-MarkdownAnchor -GroupNumber "-" -GroupName "A valid name"} |
                Should -Throw -ExceptionType ArgumentException
         }
    }

    Describe -tag "Markdown" -name 'Test HTML document anchors' {
        It "Test Valid Group Data: <GroupNumber> <GroupName>" -ForEach @(
            @{ GroupNumber = " 1"; GroupName = "A leading space" },
            @{ GroupNumber = "99 "; GroupName = "The trailing space"}
        ){
            $Anchor = New-MarkdownAnchor -GroupNumber $GroupNumber -GroupName $GroupName
            $Anchor.StartsWith("#$GoupNumber") | Should -BeTrue
            $Anchor -Contains " " | Should -BeFalse
            $GroupName.Split(' ').ForEach{
                $Anchor -Like "*$($_.ToLower())*" | Should -BeTrue -Because "$Anchor contains $($_.ToLower())"}
        }
    }
}