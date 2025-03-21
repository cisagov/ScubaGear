using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

# The purpose of these tests is to verify that the functions used to update OPA are working.

Describe "Update OPA" {
    It "Determine if OPA needs to be updated" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        # The current version of OPA used in SG is found in PowerShell/ScubaGear/ScubaGear.psm1
        # in the variable DefaultOPAVersion
        $ExpectedCurrentOPAVersion = [ScubaConfig]::GetOpaVersion()
        # Call the function
        . $ScriptPath
        $ReturnValues = Confirm-OpaUpdateRequirements -RepoPath $RepoRootPath
        # Check the results
        $ActualCurrentOPAVersion = $ReturnValues["CurrentOPAVersion"]
        $LatestOPAVersion = $ReturnValues["LatestOPAVersion"]
        # The latest version of OPA is found here:
        # https://github.com/open-policy-agent/opa/releases
        $LatestOPAVersion | Should -Be "1.2.0"
        $ActualCurrentOPAVersion | Should -Be $ExpectedCurrentOPAVersion
    }
    It "Update OPA version in config module" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        $VersionInScubaConfig = "1.0.2"
        # Call the function
        . $ScriptPath
        Update-OpaVersion -RepoPath $RepoRootPath -CurrentOpaVersion "1.0.1" -LatestOpaVersion $VersionInScubaConfig
        # Check the results
        $CurrentOPAVersion = [ScubaConfig]::GetOpaVersion()
        $CurrentOPAVersion | Should -Be $VersionInScubaConfig
    }
    It "Update acceptable versions in support module" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        $SupportPath = Join-Path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/Support/Support.psm1'
        # Call the function
        . $ScriptPath
        Update-OpaVersion -RepoPath $RepoRootPath -CurrentOpaVersion "1.0.1" -LatestOpaVersion "1.0.2"
        # Check the results
        # Find all specific lines with this comment.
        $MatchedLines = Select-String -Path $SupportPath -Pattern "# End Versions" -SimpleMatch
        # There should be only 1 line in the support module that matches
        $MatchedLines.Count | Should -Be 1
        # Get that 1 line and test to see if it contains the new value.
        $UpdatedLine = $MatchedLines[0].Line
        $UpdatedLine | Should -Match ".1.0.2"  # This is a regex test.
    }
}