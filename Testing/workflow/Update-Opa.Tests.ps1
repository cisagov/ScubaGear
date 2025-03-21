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
        # This value will need to be updated from time to time.
        $LatestOPAVersion | Should -Be "1.2.0"
        $ActualCurrentOPAVersion | Should -Be $ExpectedCurrentOPAVersion
    }
    It "Update OPA version in config and support" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        $ConfigPath = Join-path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1' -Resolve
        $SupportPath = Join-Path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/Support/Support.psm1' -Resolve
        # Setup mock values
        $MockCurrentVersion = "1.1.1"
        $MockLatestVersion = "33.44.55"
        $DefaultOPAVersionVar = "[ScubaConfig]::ScubaDefault('DefaultOPAVersion')"
        # Call the function
        . $ScriptPath
        Update-OpaVersion `
            -RepoPath $RepoRootPath `
            -CurrentOpaVersion $MockCurrentVersion `
            -LatestOpaVersion $MockLatestVersion
        # Check the results at the file level
        $ConfigPath | Should -FileContentMatchExactly $MockLatestVersion
        $SupportPath | Should -FileContentMatchExactly $DefaultOPAVersionVar
        # For support, check specifically.
        # Find all specific lines with this comment.
        $MatchedLines = Select-String -Path $SupportPath -Pattern "# End Versions" -SimpleMatch
        # There should be only 1 line in the support module that matches
        $MatchedLines.Count | Should -Be 1
        # Get that 1 line and test to see if it contains the new value.
        $UpdatedLine = $MatchedLines[0].Line
        Write-Warning "The updated line is"
        Write-Warning $UpdatedLine
        $UpdatedLine | Should -Match ".`'$DefaultOPAVersionVar`'."  # This is a regex test.
    }
}