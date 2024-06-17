function Initialize-ScubaGearForTesting
{
  Write-Output 'Initializing ScubaGear for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Output 'The repo root path is'
  Write-Output $RepoRootPath
  Write-Output 'Importing function Initialize-Scuba...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Write-Output 'Calling Initialize ScubaGear...'
  Initialize-SCuBA
}

Export-ModuleMember -Function @(
  'Initialize-ScubaGearForTesting'
)