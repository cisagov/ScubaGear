function Initialize-ScubaGearForTesting {
  <#
    .SYNOPSIS
      Initializes ScubaGear, which installs the necessary modules and tools to run ScubaGear.
  #>

  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Install-ScubaDependencies
  Write-Debug 'Calling Initialize ScubaGear...'
  $Outputs = Install-ScubaDependencies
  return $Outputs
}
