function Initialize-ScubaGearForTesting {
  <#
    .SYNOPSIS
      Initializes ScubaGear, which installs the necessary modules and tools to run ScubaGear.
  #>

  # Write-Debug 'Initializing ScubaGear for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  # Write-Debug 'The repo root path is'
  # Write-Debug $RepoRootPath
  # Write-Debug 'Importing function Initialize-Scuba...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Write-Debug 'Calling Initialize ScubaGear...'
  $Outputs = Initialize-SCuBA
  return $Outputs
}
