BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
}

Describe 'Initialize-Scuba' {
  It 'Teams should be installed' {
    $allPlanets.Count | Should -Be 8
    Get-Module -ListAvailable -Name 'MicrosoftTeams' | Should -BeTrue
  }
}