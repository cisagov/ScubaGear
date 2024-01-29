Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/Support.psm1") -Function 'Copy-ScubaConfigFile' -Force

InModuleScope Support {
    Describe "Copy sample config files to specified directory" {
        $SampleFiles = @(
            "aad-config.yaml",
            "defender-config.yaml",
            "sample-config.json",
            "sample-config.yaml"
        )
        BeforeAll{
            $SampleConfigCopyFolder = Join-Path -Path $env:Temp -ChildPath 'samples/config-files'
            if (Test-Path -Path $SampleConfigCopyFolder){
                Remove-Item -Path $SampleConfigCopyFolder -Recurse -Force
            }
        }
        It "Call Copy-ScubaSampleConfigFile with bad destination" {
            {Copy-ScubaSampleConfigFile -Destination "$SampleConfigCopyFolder\`tInvalid-"} |
                Should -Throw -Because "directory does not exist."
        }
        It "Call Copy-ScubaSampleConfigFile with good destination"{
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -Not -BeTrue
            {Copy-ScubaSampleConfigFile -Destination $SampleConfigCopyFolder} |
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
        It "Call Copy-ScubaSampleConfigFile already exists - Not Force update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "aad-config.yaml")).CreationTime
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -BeTrue
            {Copy-ScubaSampleConfigFile -Destination $SampleConfigCopyFolder} |
                Should -Throw -ExpectedMessage "Scuba copy module files failed."
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "aad-config.yaml")).CreationTime
            $PreviousCreateTime -eq $CurrentCreateTime | Should -BeTrue
        }
        It "Call Copy-ScubaSampleConfigFile already exists -  Force Update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "aad-config.yaml")).CreationTime
            Test-Path -Path $SampleConfigCopyFolder -PathType Container | Should -BeTrue
            {Copy-ScubaSampleConfigFile -Destination $SampleConfigCopyFolder -Force} |
                Should -Not -Throw
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SampleConfigCopyFolder -ChildPath "aad-config.yaml")).CreationTime
            ($CurrentCreateTime -ge $PreviousCreateTime) | Should -BeTrue -Because "$($CurrentCreateTime) vs $($PreviousCreateTime)"
        }
    }
}
