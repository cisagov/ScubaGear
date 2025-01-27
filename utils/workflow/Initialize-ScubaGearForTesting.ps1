function Initialize-ScubaGearForTesting {
  <#
    .SYNOPSIS
      Initializes ScubaGear, which installs the necessary modules and tools to run ScubaGear.
  #>

  Write-Information 'Initializing ScubaGear for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Information 'The repo root path is'
  Write-Information $RepoRootPath
  Write-Information 'Importing function Initialize-Scuba...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Write-Information 'Calling Initialize ScubaGear...'
  $Outputs = Initialize-SCuBA
  return $Outputs
}
