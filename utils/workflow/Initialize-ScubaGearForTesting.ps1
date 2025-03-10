function Initialize-ScubaGearForTesting {
  <#
    .SYNOPSIS
      Initializes ScubaGear, which installs the necessary modules and tools to run ScubaGear.
  #>

  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Write-Debug 'Calling Initialize ScubaGear...'
  $Outputs = Initialize-SCuBA
  return $Outputs
}
