function Install-Selenium 
{
  Install-Module -Name Selenium -Scope CurrentUser -Force
  Import-Module -Name Selenium
  ..\..\Testing\Functional\SmokeTest\UpdateSelenium.ps1
  # Workaround for Selenium. Loading psm1 instead of psd1
  Import-Module -Name (Get-Module -Name Selenium -ListAvailable).Path -Force
}

Export-ModuleMember -Function @(
  'Install-Selenium'
)