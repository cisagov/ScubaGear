function Initialize-ScubaGearForTesting
{
  Write-Output 'Initializing ScubaGear for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear') -Function Initialize-Scuba
  Initialize-SCuBA
}

Export-ModuleMember -Function @(
  'Initialize-ScubaGearForTesting'
)