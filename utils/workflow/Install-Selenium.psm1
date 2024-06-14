function Install-Selenium 
{
  Install-Module -Name Selenium -Scope CurrentUser -Force
  Import-Module -Name Selenium
  Get-Location
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Host 'Repo Root Path is'
  Write-Host $RepoRootPath
  Join-Path -Path $RepoRootPath -ChildPath 'Testing/Functional/SmokeTest/UpdateSelenium.ps1'
  # ..\..\Testing\Functional\SmokeTest\UpdateSelenium.ps1
  # Workaround for Selenium. Loading psm1 instead of psd1
  Import-Module -Name (Get-Module -Name Selenium -ListAvailable).Path -Force
}

Export-ModuleMember -Function @(
  'Install-Selenium'
)