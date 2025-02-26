# The purpose of this test is to verify that the required PS modules were installed.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Initialize-ScubaGearForTesting.ps1
  # Initialize SG
  $Outputs = Initialize-ScubaGearForTesting
  # Whitelist the outputs that we are interested in finding
  $global:PSGallery = $false
  $global:DownloadedOPAVersion = $false
  $global:SetupTime = $false
  $global:SetupTimeValue = 0
  $global:SetupTimeThreshold = 1000 # The max time it should take to initialize SG
  # Loop over the various outputs in the PowerShell pipeline, looking for outputs
  # that start with these exact strings.  For more info:
  # https://www.scriptrunner.com/en/blog/pipeline-ready-advanced-powershell
  foreach ($Output in $Outputs) {
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
        $global:SetupTimeValue = [int]$Output.split(":")[1].Trim()
      }
    }
  }
}

# Use Write-Warning b/c other writes don't actually write
Write-Warning "Getting required modules..."
try {
  . PowerShell\ScubaGear\RequiredVersions.ps1
}
catch {
  throw "Unable to find RequiredVersions.ps1"
}
if ($ModuleList) {
  Write-Warning "Found list of modules!"
}
else {
  Write-Warning 'Did NOT find list of modules!!'
}

Describe "Initialize-ScubaGear Modules Check" {
  foreach ($Module in $ModuleList) {
    $global:ModuleName = $Module.ModuleName
    It "Module $global:moduleName should be installed" {
      $module = Get-Module -ListAvailable -Name $global:ModuleName
      $module | Should -Not -BeNullOrEmpty
    }
  }
}

Describe "Initialize-ScubaGear Output Check" {
  It "PSGallery should be trusted" {
    $global:PSGallery | Should -Be $true
  }
  It "OPA should be downloaded" {
    $global:DownloadedOPAVersion | Should -Be $true
  }
  It "Setup time should be minimal" {
    $global:SetupTime | Should -Be $true
    $global:SetupTimeValue | Should -BeLessThan $global:SetupTimeThreshold
  }
}
