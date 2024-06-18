BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
}

$moduleName = 'MicrosoftTeams'

Describe "Check for installed PowerShell modules" {
  It "Module $moduleName should be installed" {
      $module = Get-Module -ListAvailable -Name 'MicrosoftTeams'
      $module | Should -Not -BeNullOrEmpty
  }
}
