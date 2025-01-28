# The purpose of this test is to verify that the required PS modules were installed.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Initialize-ScubaGearForTesting.ps1
  # Initialize SG
  $global:Outputs = Initialize-ScubaGearForTesting
}

# Use Write-Warning b/c other writes don't actually write
Write-Output "Getting required modules..."
try {
  . PowerShell\ScubaGear\RequiredVersions.ps1
}
catch {
  throw "Unable to find RequiredVersions.ps1"
}
if ($ModuleList) {
  Write-Output "Found list of modules!"
}
else {
  Write-Warning 'Did NOT find list of modules!!'
}

Describe "PowerShell Modules Check" {
  foreach ($Module in $ModuleList) {
    $global:ModuleName = $Module.ModuleName
    It "Module $global:moduleName should be installed" {
      $module = Get-Module -ListAvailable -Name $global:ModuleName
      $module | Should -Not -BeNullOrEmpty
    }
  }
}

Describe "Initialize-ScubaGear Output Check" {
  foreach ($Output in $global:Outputs) {
    $global:PSGallery = $false
    $global:DownloadedOPAVersion = $false
    $global:SetupTime = $false
    $global:SetupTimeValue = 0
    if ($Output.GetType().Name -eq "String") {
      Write-Warning $Output
      if ($Output.StartsWith("PSGallery is trusted")) {
        $global:PSGallery = $true
      }
      elseif ($Output.StartsWith("Downloaded OPA version")) {
        $global:DownloadedOPAVersion = $true
      }
      elseif ($Output.StartsWith("ScubaGear setup time elapsed")) {
        $global:SetupTime = $true
        $global:SetupTimeValue = [int]$Output.split(":")[1]
      }
    }
  }
  It "PSGallery should be trust" {
    $global:PSGallery | Should -Be $true
  }
  It "OPA should be downloaded" {
    $global:DownloadedOPAVersion | Should -Be $true
  }
  It "Setup time should be minimal" {
    $global:SetupTime | Should -Be $true
    $global:SetupTimeValue | Should -BeLessThan 1000
  }
}
