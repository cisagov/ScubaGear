BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
}

$moduleName = 'MicrosoftTeams'

Describe "Check for installed PowerShell module" {
    It "Module $moduleName should be installed" {
        $module = Get-Module -ListAvailable -Name $moduleName
        $module | Should -Not -BeNullOrEmpty
    }
}
