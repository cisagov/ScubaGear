# using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

# The purpose of this test is to verify that the functions used to update OPA are working.

Describe "Update OPA" {
    It "Determine if OPA needs to be updated" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        Write-Warning "The repo root path is $RepoRootPath"
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        Write-Warning "The script path is $ScriptPath"
        # Call the function
        . $ScriptPath
        $ReturnValues = Confirm-OpaUpdateRequirements -RepoPath $RepoRootPath
        # The latest version of OPA is found here:
        # https://github.com/open-policy-agent/opa/releases
        $LatestOPAVersion = $ReturnValues["LatestOPAVersion"]
        $LatestOPAVersion | Should -Be "1.2.0"
        # The current version of OPA used in SG is found
        # in PowerShell/ScubaGear/ScubaGear.psm1
        # in the variable DefaultOPAVersion
        # $ScubaConfigPath = Join-Path -Path $RepoRootPath -ChildPath PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1
        # Write-Warning "The Scuba Config path is $ScubaConfigPath"
        # $ScubaConfig = New-Object ScubaConfig
        # $Version = $ScubaConfig.GetOpaVersion()
        # Write-Warning "The version from the getter is $Version"

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