function Initialize-ScubaGearForTesting {
  <#
    .SYNOPSIS
      Initializes ScubaGear, which installs the necessary modules and tools to run ScubaGear.
  #>

  Write-Output 'Initializing ScubaGear for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Output 'The repo root path is'
  Write-Output $RepoRootPath
  Write-Output 'Importing function Initialize-Scuba...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Write-Output 'Calling Initialize ScubaGear...'
  Initialize-SCuBA
}
