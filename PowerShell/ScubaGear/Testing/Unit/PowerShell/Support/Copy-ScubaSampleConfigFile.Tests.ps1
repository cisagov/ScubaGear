Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/Support.psm1") -Function 'Copy-ScubaConfigFile' -Force

InModuleScope Support {
    Describe "Copy sample config files to specified directory" {
        $SampleFiles = (Get-ChildItem PowerShell/ScubaGear/Sample-Config-Files).Name
        BeforeAll{
            $SampleConfigCopyFolder = Join-Path -Path $env:Temp -ChildPath 'samples/config-files'
            if (Test-Path -Path $SampleConfigCopyFolder){
                Remove-Item -Path $SampleConfigCopyFolder -Recurse -Force
            }
        }
        It "Call Copy-SCuBASampleConfigFile with bad destination" {
            {Copy-SCuBASampleConfigFile -Destination "$SampleConfigCopyFolder\`tInvalid-"} |
                Should -Throw -Because "directory does not exist."
        }
        It "Call Copy-SCuBASampleConfigFile with good destination"{
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -Not -BeTrue
            {Copy-SCuBASampleConfigFile -Destination $SampleConfigCopyFolder} |
                Should -Not -Throw
        }
        It "Top level sample file, <_>, is copied" -ForEach $SampleFiles {
            $ItemPath = Join-Path -Path $SampleConfigCopyFolder -ChildPath $_
            Test-Path -Path $ItemPath -PathType Leaf | Should -BeTrue
        }
        It "Sample document, <_>, is read only" -ForEach $SampleFiles{
            $ItemPath = Join-Path -Path $SampleConfigCopyFolder -ChildPath $_
            Get-Item -Path $ItemPath | Select-Object IsReadyOnly | Should -BeTrue
        }
        It "Call Copy-SCuBASampleConfigFile already exists - Not Force update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "full_config.yaml")).CreationTime
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -BeTrue
            {Copy-SCuBASampleConfigFile -Destination $SampleConfigCopyFolder} |
                Should -Throw -ExpectedMessage "Scuba copy module files failed."
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "full_config.yaml")).CreationTime
            $PreviousCreateTime -eq $CurrentCreateTime | Should -BeTrue
        }
        It "Call Copy-SCuBASampleConfigFile already exists -  Force Update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "full_config.yaml")).CreationTime
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -BeTrue
            {Copy-SCuBASampleConfigFile -Destination $SampleConfigCopyFolder -Force} |
                Should -Not -Throw
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "full_config.yaml")).CreationTime
            ($CurrentCreateTime -ge $PreviousCreateTime) | Should -BeTrue -Because "$($CurrentCreateTime) vs $($PreviousCreateTime)"
        }
    }
}
