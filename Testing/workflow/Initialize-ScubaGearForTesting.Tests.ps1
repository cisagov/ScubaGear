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
Write-Information -MessageData "Getting required modules..."
try {
  . PowerShell\ScubaGear\RequiredVersions.ps1
}
catch {
  throw "Unable to find RequiredVersions.ps1"
}
if ($ModuleList) {
  Write-Information -MessageData "Found list of modules!"
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
      Write-Information -MessageData  $Output
      $AutoTrust = $false
      $TrustPSGallery = $false
      $Time = $false
      $Key = $Output.split(":")[0]
      # Write-Warning " The key is $Key"
      $Value = $Output.split(":")[1]
      # Write-Warning " The value is $Value"
      if ($Key -eq  "AutoTrust") {
        $AutoTrust = $true
      }
      elseif ($Key -eq "TrustPSGallery") {
        $TrustPSGallery = $true
      }
      elseif ($Key -eq "Time") {
        $Time = $true
        $Value | Should -BeLessThan 1000
      }
      else {
        # If we get to here, we have encountered an unexpected output, so fail
        # TODO is there a smarter way to just fail in Pester?  This seems convoluted.
        $true | Should -Be $false
      }
    }
    Write-Information -MessageData  "AutoTrust"
    $AutoTrust | Should -Be $true
    Write-Information -MessageData  "TrustPSGallery"
    $TrustPSGallery | Should -Be $true
    Write-Information -MessageData  "Time"
    $Time | Should -Be $true
  }
}
