# The purpose of this test is to verify that the functions used to update OPA are working.

Describe "Update OPA" {
    It "Determine if OPA needs to be updated" {
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
        . $ScriptPath
        $ReturnValues = Confirm-OpaUpdateRequirements -RepoPath $RepoRootPath
        # The latest version of OPA is found here:
        # https://github.com/open-policy-agent/opa/releases
        $LatestOPAVersion = $ReturnValues["LatestOPAVersion"]
        $LatestOPAVersion | Should -Be "1.2.0"
        # The current version of OPA used in SG is found
        # in PowerShell/ScubaGear/ScubaGear.psm1
        # in the variable DefaultOPAVersion
        $ScubaConfigPath = Join-Path -Path $RepoPath -ChildPath PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1
        $OPAVerRegex = "\'\d+\.\d+\.\d+\'"
        $DefaultVersionPattern = "DefaultOPAVersion = $OPAVerRegex"
        $ScubaConfigModule = Get-Content $ScubaConfigPath -Raw
        $ExpectedCurrentOPAVersion = '0.0.0'
        if ($ScubaConfigModule -match $DefaultVersionPattern) {
            $ExpectedCurrentOPAVersion = ($Matches[0] -split "=")[1] -replace " ", ""
            $ExpectedCurrentOPAVersion = $CurrentOPAVersion -replace "'", ""
            Write-Warning "The expected current OPA version is $CurrentOPAVersion."
        }
        else {
            Write-Error "Failed to get the current OPA version from ScubaConfig.psm1."
        }
        $ActualCurrentOPAVersion = $ReturnValues["CurrentOPAVersion"]
        $ActualCurrentOPAVersion | Should -Be $ExpectedCurrentOPAVersion
    }
}