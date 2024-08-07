# The purpose of this test is to verify that the required
# PS modules were installed.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
  Import-Module -Name .\utils\workflow\Initialize-ScubaGearForTesting
  Import-Module -Name .\PowerShell\ScubaGear
  Initialize-ScubaGearForTesting
}

# Use Write-Warning b/c other writes don't actually write
Write-Warning 'Getting required modules...'
try {
  . PowerShell\ScubaGear\RequiredVersions.ps1
}
catch {
  throw "Unable to find RequiredVersions.ps1"
}
if ($ModuleList) {
  Write-Warning 'Found list of modules!'
}
else {
  Write-Warning 'Did NOT find list of modules!!'
}

Describe "Check for PowerShell modules" {
  foreach ($Module in $ModuleList) {
    $global:ModuleName = $Module.ModuleName
    It "Module $global:moduleName should be installed" {
      $module = Get-Module -ListAvailable -Name $global:ModuleName
      $module | Should -Not -BeNullOrEmpty
    }
  }
}
