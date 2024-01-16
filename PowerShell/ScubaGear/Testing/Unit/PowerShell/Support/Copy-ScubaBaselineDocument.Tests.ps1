Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/Support.psm1") -Function 'Copy-ScubaBaselineDocument' -Force

InModuleScope Support {
    Describe "Copy Secure Baseline Documents to specified directory" {
        $Products = @(
            "teams",
            "exo",
            "defender",
            "aad",
            "powerplatform",
            "sharepoint"
        )

        BeforeAll{
            $SecureBaselineCopyFolder = Join-Path -Path $env:Temp -ChildPath 'SecureBaseline'
            if (Test-Path -Path $SecureBaselineCopyFolder){
                Remove-Item -Path $SecureBaselineCopyFolder -Recurse -Force
            }
        }
        It "Call Copy-ScubaBaselineDocument with bad destination" {
            {Copy-ScubaBaselineDocument -Destination "$SecureBaselineCopyFolder\`tInvalid-"} |
                Should -Throw -Because "directory does not exist."
        }
        It "Call Copy-ScubaBaselineDocument with good destination"{
            Test-Path -Path $SecureBaselineCopyFolder -PathType Container | Should -Not -BeTrue
            {Copy-ScubaBaselineDocument -Destination $SecureBaselineCopyFolder} |
                Should -Not -Throw
        }
        It "Baseline document for <_> is copied" -ForEach $Products {
            $ItemPath = Join-Path -Path $SecureBaselineCopyFolder -ChildPath "$_.md"
            Test-Path -Path $ItemPath -PathType Leaf | Should -BeTrue
        }
        It "Baseline document <_>.md is read only" -ForEach $Products{
            $ItemPath = Join-Path -Path $SecureBaselineCopyFolder -ChildPath "$_.md"
            Get-Item -Path $ItemPath | Select-Object IsReadyOnly | Should -BeTrue
        }
        It "Call Copy-ScubaBaselineDocument already exists - Not Force update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SecureBaselineCopyFolder -ChildPath 'aad.md')).CreationTime
            Test-Path -Path $SecureBaselineCopyFolder -PathType Container | Should -BeTrue
            {Copy-ScubaBaselineDocument -Destination $SecureBaselineCopyFolder} |
                Should -Not -Throw
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SecureBaselineCopyFolder -ChildPath 'aad.md')).CreationTime
            $PreviousCreateTime -eq $CurrentCreateTime | Should -BeTrue
        }
        It "Call Copy-ScubaBaselineDocument already exists -  Force Update"{
            $PreviousCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SecureBaselineCopyFolder -ChildPath 'aad.md')).CreationTime
            Test-Path -Path $SecureBaselineCopyFolder -PathType Container | Should -BeTrue
            {Copy-ScubaBaselineDocument -Destination $SecureBaselineCopyFolder -Force} |
                Should -Not -Throw    
            $CurrentCreateTime = [System.DateTime](Get-Item -Path (Join-Path -Path $SecureBaselineCopyFolder -ChildPath 'aad.md')).CreationTime
            ($CurrentCreateTime -ge $PreviousCreateTime) | Should -BeTrue -Because "$($CurrentCreateTime) vs $($PreviousCreateTime)"
        }
    }
}