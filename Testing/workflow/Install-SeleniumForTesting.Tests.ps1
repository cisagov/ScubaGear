# The purpose of this test is to verify that Selenium was installed.

BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Install-SeleniumForTesting
  Install-SeleniumForTesting
}

Describe "Check for Selenium" {
  It "Selenium should be installed" {
    $module = Get-Module -ListAvailable -Name 'Selenium'
    $module | Should -Not -BeNullOrEmpty
  }
}