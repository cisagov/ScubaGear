BeforeDiscovery 
{
  # Install the required modules
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Initialize-ScubaGearForTesting
  # Get the list of required modules
  # $ModuleParentDir = Split-Path -Path (Get-Module ScubaGear).Path -Parent
  # Write-Output 'Module parent dir:'
  # Write-Output $ModuleParentDir
  # try 
  # {
  #   $RequiredModulesPath = Join-Path -Path $ModuleParentDir -ChildPath 'RequiredVersions.ps1' -Resolve
  #   Write-Output 'Required modules path:'
  #   Write-Output $RequiredModulesPath
  #   . $RequiredModulesPath
  # }
  # catch 
  # {
  #   throw "Unable to find RequiredVersions.ps1"
  # }
  # if ($ModuleList) 
  # {
  #   Write-Information "Found list of modules"
  # }
  # else 
  # {
  #   Write-Information "Did NOT find list of modules"
  # }
}

BeforeDiscovery -ScriptBlock 
{
  Write-Output 'This is the other BD.'
}

Describe 'Initialize-Scuba'
{
  # Test the list of required modules
  It 'Teams should be installed' 
  {
    Get-Module -ListAvailable -Name 'MicrosoftTeams' | Should -BeTrue
  }
  It 'ExchangeOnlineManagement should be installed' {
    Get-Module -ListAvailable -Name 'ExchangeOnlineManagement' | Should -BeTrue
  }
  It 'Microsoft.Online.SharePoint.PowerShell should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Online.SharePoint.PowerShell' | Should -BeTrue
  }
  It 'PnP.PowerShell should be installed' {
    Get-Module -ListAvailable -Name 'PnP.PowerShell' | Should -BeTrue
  }
  It 'Microsoft.PowerApps.Administration.PowerShell should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.PowerApps.Administration.PowerShell' | Should -BeTrue
  }
  It 'Microsoft.PowerApps.PowerShell should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.PowerApps.PowerShell' | Should -BeTrue
  }
  It 'Microsoft.Graph.Authentication should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Authentication' | Should -BeTrue
  }
  It 'Microsoft.Graph.Beta.Users should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Beta.Users' | Should -BeTrue
  }
  It 'Microsoft.Graph.Beta.Groups should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Beta.Groups' | Should -BeTrue
  }
  It 'Microsoft.Graph.Beta.Identity.DirectoryManagement should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Beta.Identity.DirectoryManagement' | Should -BeTrue
  }
  It 'Microsoft.Graph.Beta.Identity.Governance should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Beta.Identity.Governance' | Should -BeTrue
  }
  It 'Microsoft.Graph.Beta.Identity.SignIns should be installed' {
    Get-Module -ListAvailable -Name 'Microsoft.Graph.Beta.Identity.SignIns' | Should -BeTrue
  }
  It 'powershell-yaml should be installed' {
    Get-Module -ListAvailable -Name 'powershell-yaml' | Should -BeTrue
  }
}