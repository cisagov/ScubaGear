using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

# The purpose of these tests is to verify that the functions used to update OPA are working.

Describe "Update OPA" {

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

    It "Update OPA version in ScubaConfigDefaults.json" {
        # Setup important paths
        $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-Opa.ps1' -Resolve
        $ConfigDefaultsPath = Join-path -Path $PSScriptRoot -ChildPath '../../PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfigDefaults.json' -Resolve

        # Setup mock values
        $MockCurrentVersion = "1.1.1"  # The old default (expect this to be added to compatibleOpaVersions)
        $MockLatestVersion = "33.44.55"  # The new default (expect this to replace OPAVersion)

        # Call the function
        . $ScriptPath
        Update-OpaVersion `
            -RepoPath $RepoRootPath `
            -CurrentOpaVersion $MockCurrentVersion `
            -LatestOpaVersion $MockLatestVersion

        # Check the results at the file level
        $ConfigDefaultsPath | Should -FileContentMatchExactly $MockLatestVersion
        $ConfigDefaultsPath | Should -FileContentMatchExactly $MockCurrentVersion

        # Parse the updated ScubaConfig defaults JSON
        $UpdatedDefaults = Get-Content -Path $ConfigDefaultsPath -Raw | ConvertFrom-Json

        # Check that OPAVersion and compatibleOpaVersions are updated correctly
        $UpdatedDefaults.defaults.OPAVersion | Should -Be $MockLatestVersion
        $UpdatedDefaults.metadata.compatibleOpaVersions | Should -Contain $MockCurrentVersion

        $CountOfCurrent = ($UpdatedDefaults.metadata.compatibleOpaVersions | Where-Object { $_ -eq $MockCurrentVersion }).Count
        $CountOfCurrent | Should -Be 1
    }
}