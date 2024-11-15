function Install-SeleniumForTesting {
  <#
    .DESCRIPTION
      Installs Selenium for ScubaGear testing
  #>

  Write-Output 'Installing Selenium for testing...'
  Install-Module -Name Selenium -Scope CurrentUser -Force
  Import-Module -Name Selenium
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Join-Path -Path $RepoRootPath -ChildPath 'Testing/Functional/SmokeTest/UpdateSelenium.ps1'
  # Workaround for Selenium. Loading psm1 instead of psd1
  Import-Module -Name (Get-Module -Name Selenium -ListAvailable).Path -Force
}
