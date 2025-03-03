# The purpose of this test is to verify that the functions used to update OPA are working.

Describe "Update OPA" {
    It "Determine if OPA needs to be updated" {
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
        . $ScriptPath
        $ReturnValues = Determine-OpaUpdateRequirements -RepoPath $RepoRootPath
        $LatestOPAVersion = $ReturnValues["LatestOPAVersion"]
        $LatestOPAVersion | Should -Be "1.2.0"
    }
}