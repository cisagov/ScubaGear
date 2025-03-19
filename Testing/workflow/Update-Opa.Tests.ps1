using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

# The purpose of this test is to verify that the functions used to update OPA are working.

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
        # Call the function
        . $ScriptPath
        Update-OpaVersion -RepoPath $RepoRootPath -CurrentOpaVersion "1.0.0" -LatestOpaVersion "1.1.1"
        $CurrentOPAVersion = [ScubaConfig]::GetOpaVersion()
        $CurrentOPAVersion | Should -Be "1.1.1"
    }
}