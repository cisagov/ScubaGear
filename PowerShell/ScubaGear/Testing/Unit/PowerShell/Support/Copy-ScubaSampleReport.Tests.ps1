Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/Support.psm1") -Function 'Copy-ScubaSampleReport' -Force

InModuleScope Support {
    Describe "Copy Sample Reports to specified directory" {
        $SampleFiles = @(
            "BaselineReports.html",
            "ProviderSettingsExport.json",
            "TestResults.json"
        )
        $SampleFolders = @(
            "individualReports"
            "individualReports/images"
        )
        BeforeAll{
            $SampleReportsCopyFolder = Join-Path -Path $env:Temp -ChildPath 'samples/reports'
            if (Test-Path -Path $SampleReportsCopyFolder){
                Remove-Item -Path $SampleReportsCopyFolder -Recurse -Force
            }
        }
        It "Call Copy-SCuBASampleReports with bad destination" {
            {Copy-SCuBASampleReport -Destination "$SampleReportsCopyFolder\`tInvalid-"} |
                Should -Throw -Because "directory does not exist."
        }
        It "Call Copy-SCuBASampleReports with good destination"{
            Test-Path -Path $SampleReportsCopyFolder -PathType Container | Should -Not -BeTrue
            {Copy-SCuBASampleReport -Destination $SampleReportsCopyFolder} |
                Should -Not -Throw
        }
        It "Top level sample file, <_>, is copied" -ForEach $SampleFiles {
            $ItemPath = Join-Path -Path $SampleReportsCopyFolder -ChildPath $_
            Test-Path -Path $ItemPath -PathType Leaf | Should -BeTrue
        }
        It "Sample sub directory, <_>, is copied" -ForEach $SampleFolders {
            $ItemPath = Join-Path -Path $SampleReportsCopyFolder -ChildPath $_
            Test-Path -Path $ItemPath -PathType Container | Should -BeTrue
        }
        It "Sample document, <_>, is read only" -ForEach $SampleFiles{
            $ItemPath = Join-Path -Path $SampleReportsCopyFolder -ChildPath "$_"
            Get-Item -Path $ItemPath | Select-Object IsReadyOnly | Should -BeTrue
        }
        It "Sample folder, <_>, is read only" -ForEach $SampleFolders{
            $ItemPath = Join-Path -Path $SampleReportsCopyFolder -ChildPath "$_"
            Get-Item -Path $ItemPath | Select-Object IsReadyOnly | Should -BeTrue
        }
        It "Call Copy-SCuBASampleReports already exists - Not Force update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleReportsCopyFolder -ChildPath "BaselineReports.html")).CreationTime
            Test-Path -Path $SampleReportsCopyFolder -PathType Container | Should -BeTrue
            {Copy-SCuBASampleReport -Destination $SampleReportsCopyFolder} |
                Should -Throw -ExpectedMessage "Scuba copy module files failed."
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleReportsCopyFolder -ChildPath "BaselineReports.html")).CreationTime
            $PreviousCreateTime -eq $CurrentCreateTime | Should -BeTrue
        }
        It "Call Copy-SCuBASampleReports already exists -  Force Update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleReportsCopyFolder -ChildPath "BaselineReports.html")).CreationTime
            Test-Path -Path $SampleReportsCopyFolder -PathType Container | Should -BeTrue
            {Copy-SCuBASampleReport -Destination $SampleReportsCopyFolder -Force} |
                Should -Not -Throw
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleReportsCopyFolder -ChildPath "BaselineReports.html")).CreationTime
            ($CurrentCreateTime -ge $PreviousCreateTime) | Should -BeTrue -Because "$($CurrentCreateTime) vs $($PreviousCreateTime)"
        }
    }
}
