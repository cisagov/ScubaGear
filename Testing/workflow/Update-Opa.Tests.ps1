using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

# The purpose of these tests is to verify that the functions used to update OPA are working.

Describe "Update OPA" {

    BeforeAll {
        function Invoke-RestMethod {  [PSCustomObject]@{'tag_name' = 'v1.3.0'} }
    }

    It "Determine if OPA needs to be updated" {
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{'tag_name' = 'v9.9.0'}
        }

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

        # Should match mocked version returned from Invoke-RestMethod
        $LatestOPAVersion | Should -Be "9.9.0"
        $ActualCurrentOPAVersion | Should -Be $ExpectedCurrentOPAVersion
    }

    It "Update OPA version in config and support" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        $ConfigPath = Join-path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1' -Resolve
        $SupportPath = Join-Path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/Support/Support.psm1' -Resolve
        # Setup mock values
        $MockCurrentVersion = "1.1.1"  # The version inserted into Support
        $MockLatestVersion = "33.44.55"  # The version inserted into Config
        # Call the function
        . $ScriptPath
        Update-OpaVersion `
            -RepoPath $RepoRootPath `
            -CurrentOpaVersion $MockCurrentVersion `
            -LatestOpaVersion $MockLatestVersion
        # Check the results at the file level
        $ConfigPath | Should -FileContentMatchExactly $MockLatestVersion
        $SupportPath | Should -FileContentMatchExactly $MockCurrentVersion
        # For support, check specifically.
        # Find all specific lines with this comment.
        $MatchedLines = Select-String -Path $SupportPath -Pattern "# End Versions" -SimpleMatch
        # There should be only 1 line in the support module that matches
        $MatchedLines.Count | Should -Be 1
        # Get that 1 line and test to see if it contains the new value.
        $UpdatedLine = $MatchedLines[0].Line
        $UpdatedLine | Should -Match ".`'$MockCurrentVersion`'."  # This is a regex test.
    }
}