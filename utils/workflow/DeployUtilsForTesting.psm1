function ConfigureScubaGearModuleForTesting
{
  <#
    .DESCRIPTION
    Unit Testing for DeployUtils
  #>
  Write-Output 'Configuring ScubaGear module for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Output 'The repo root path is'
  Write-Output $RepoRootPath
  Write-Output 'Importing function ConfigureScubaGearModule...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'utils') -Function ConfigureScubaGearModule
  Write-Output 'Calling ConfigureScubaGearModule...'
  ConfigureScubaGearModule
}

function CreateArrayOfFilePathsForTesting
{
  <#
    .DESCRIPTION
    Unit Testing for DeployUtils
  #>
  Write-Output 'Creating array of file paths for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Output 'The repo root path is'
  Write-Output $RepoRootPath
  Write-Output 'Importing function CreateArrayOfFilePaths...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'utils') -Function CreateArrayOfFilePaths
  Write-Output 'Calling CreateArrayOfFilePaths...'
  CreateArrayOfFilePaths
}

function CreateFileListForTesting
{
  <#
    .DESCRIPTION
    Unit Testing for DeployUtils
  #>
  Write-Output 'Creating file list for testing...'
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Write-Output 'The repo root path is'
  Write-Output $RepoRootPath
  Write-Output 'Importing function CreateFileList...'
  Import-Module (Join-Path -Path $RepoRootPath -ChildPath 'utils') -Function CreateFileList
  Write-Output 'Calling CreateFileList...'
  CreateFileList
}

Export-ModuleMember -Function @(
  'ConfigureScubaGearModuleForTesting',
  'CreateArrayOfFilePathsForTesting',
  'CreateFileListForTesting'
)
