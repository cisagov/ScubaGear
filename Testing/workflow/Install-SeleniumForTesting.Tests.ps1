# The purpose of this test is to verify that Selenium was installed.

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Install-SeleniumForTesting.ps1
  # Install Selenium
  Install-SeleniumForTesting
}

Describe "Selenium Check" {
  It "Selenium should be installed" {
    $module = Get-Module -ListAvailable -Name 'Selenium'
    $module | Should -Not -BeNullOrEmpty
  }
}