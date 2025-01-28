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
      # $Time = $false
      # $TimeValue = 0
      if ($Output.GetType() -is [String]) {
        Write-Warning "String:"
        Write-Warning $Output
        # $Key = $Output.split(":")[0]
        # $Value = $Output.split(":")[1]
        # if ($Key -eq  "AutoTrust") {
        #   $AutoTrust = $true
        # }
        # elseif ($Key -eq "TrustPSGallery") {
        #   $TrustPSGallery = $true
        # }
        # elseif ($Key -eq "Time") {
        #   $Time = $true
        #   $TimeValue = $Value
        # }
        # else {
        #   Write-Warning "Unexpected output"
        #   # If we get to here, we have encountered an unexpected output, so fail
        #   # TODO is there a smarter way to just fail in Pester?  This seems convoluted.
        #   # $true | Should -Be $false
        # }
      }
      else {
        Write-Warning $Output.GetType()
        Write-Warning $Output
      }
    }
    # Write-Output "AutoTrust"
    # $AutoTrust | Should -Be $true
    # Write-Output "TrustPSGallery"
    # $TrustPSGallery | Should -Be $true
    # Write-Output "Time"
    # $Time | Should -Be $true
    # $TimeValue | Should -BeLessThan 1000
  }
}
