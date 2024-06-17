BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
}

Describe 'Initialize-Scuba' {
  It 'Teams should be installed' {
    Get-Module -ListAvailable -Name 'MicrosoftTeams' | Should -BeTrue
  }
}