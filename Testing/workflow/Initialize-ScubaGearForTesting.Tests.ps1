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
  It "Expected output statements should exist and have expected values." {
    foreach ($Output in $global:Outputs) {
      $PSGallery = $false
      $DownloadedOPAVersion = $false
      $SetupTime = $false
      $SetupTimeValue = 0
      if ($Output.GetType().Name -eq 'String') {
        Write-Warning "String:"
        Write-Warning $Output
        if ($Output.StartsWith("PSGallery is trusted")) {
          $PSGallery = $true
        }
        elseif ($Output.StartsWith("Downloaded OPA version")) {
          $DownloadedOPAVersion = $true
        }
        elseif ($Output.StartsWith("ScubaGear setup time elapsed")) {
          $SetupTime = $true
          $SetupTimeValue = [int]$Output.split(":")[1]
        }
      }
      else {
        Write-Warning $Output.GetType()
        Write-Warning $Output
      }
    }
    Write-Output "PSGallery"
    $PSGallery | Should -Be $true
    Write-Output "DownloadOPAVersion"
    $DownloadedOPAVersion | Should -Be $true
    Write-Output "SetupTime"
    $SetupTime | Should -Be $true
    $SetupTimeValue | Should -BeLessThan 1000
  }
}
