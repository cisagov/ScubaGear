BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
}

$global:moduleName = 'MicrosoftTeams'

Describe "Check for installed PowerShell modules" {
  It "Module $global:moduleName should be installed" {
    $module = Get-Module -ListAvailable -Name $global:moduleName
    $module | Should -Not -BeNullOrEmpty
  }
}
