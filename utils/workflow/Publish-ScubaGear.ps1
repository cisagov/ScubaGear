#Requires -Version 5.1

function New-PrivateGallery {
  <#
    .DESCRIPTION
      Creates a new private package repository (i.e., gallery) on local file system
    .PARAMETER GalleryPath
      Path for directory to use for private gallery
    .PARAMETER GalleryName
      Name of the private gallery
    .PARAMETER Trusted
      Indicates if private gallery is registered as a trusted gallery
    .EXAMPLE
      New-PrivateGallery -Trusted
      Create new private, trusted gallery using default name and location
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ -IsValid })]
    [string]
    $GalleryRootPath = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryName = 'PrivateScubaGearGallery',
    [switch]
    $Trusted
  )

  Write-Output "Registering a new private gallery..."
  $GalleryPath = Join-Path -Path $GalleryRootPath -ChildPath $GalleryName
  if (Test-Path $GalleryPath) {
    Write-Output "Removing private gallery at $GalleryPath"
    Remove-Item -Recursive -Force $GalleryPath
  }

  New-Item -Path $GalleryPath -ItemType Directory

  $AlreadyRegistered = $false
  try {
    $AlreadyRegistered = (Get-PSRepository).Name -contains $GalleryName
  }
  catch {
    Write-Error "An error occurred when checking if $GalleryName is already registered."
    Write-Error $_.Exception
    exit 1
  }

  if ($AlreadyRegistered) {
    Write-Error "Private gallery was not created because $GalleryName is already registered."
    Write-Error "To unregister: `nUnregister-PSRepository -Name $GalleryName"
    exit 1
  }

  Write-Output "Attempting to register $GalleryName..."
  $Parameters = @{
    Name               = $GalleryName
    SourceLocation     = $GalleryPath
    PublishLocation    = $GalleryPath
    InstallationPolicy = if ($Trusted) { 'Trusted' } else { 'Untrusted' }
  }
  Register-PSRepository @Parameters
  Write-Output "The gallery was registered..."
}

function Publish-ScubaGearModule {
  <#
    .Description
      Publish ScubaGear module to private package repository
    .Parameter AzureKeyVaultUrl
      The URL of the key vault with the code signing certificate
    .Parameter CertificateName
      The name of the code signing certificate
    .Parameter ModulePath
      Path to module root directory
    .Parameter GalleryName
      Name of the private package repository (i.e., gallery)
    .Parameter OverrideModuleVersion
      Optional module version.  If provided it will use as module version. Otherwise, the current version from the manifest with a revision number is added instead.
    .Parameter PrereleaseTag
      The identifier that will be used in place of a version to identify the module in the gallery
    .Parameter NuGetApiKey
      Specifies the API key that you want to use to publish a module to the online gallery.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ [uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https' })]
    [System.Uri]
    $AzureKeyVaultUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CertificateName,
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    $ModuleSourcePath,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryName = 'PrivateScubaGearGallery',
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]
    $OverrideModuleVersion = "",
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]
    $PrereleaseTag = "",
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $NuGetApiKey
  )

  try {
    # Most of the functions called below can throw an error if something goes wrong,
    # hence the try-catch block.

    Write-Output "Copying the module to a temp location..."
    $ModuleDestinationPath = Copy-ModuleToTempLocation `
    -ModuleSourcePath $ModuleSourcePath `
    -ModuleTempPath $env:TEMP

    Write-Output "Editing the manifest file..."
    Edit-ManifestFile `
    -ModuleDestinationPath $ModuleDestinationPath `
    -OverrideModuleVersion $OverrideModuleVersion `
    -PrereleaseTag $PrereleaseTag

    Write-Output "Creating an array of the files to sign..."
    $ArrayOfFilePaths = New-ArrayOfFilePaths `
    -ModuleDestinationPath $ModuleDestinationPath

    Write-Output "Creating a file with a list of the files to sign..."
    $FileListFileName = New-FileList `
    -ArrayOfFilePaths $ArrayOfFilePaths

    Write-Output "Calling AzureSignTool function to sign scripts, manifest, and modules..."
    Use-AzureSignTool `
      -AzureKeyVaultUrl $AzureKeyVaultUrl `
      -CertificateName $CertificateName `
      -FileList $FileListFileName

    Write-Output "Creating the catalog list file..."
    $ReturnObject = New-ScubaCatalogFile `
      -ModuleDestinationPath $ModuleDestinationPath
    $CatalogFilePath = $($ReturnObject.CatalogFilePath)
    $CatalogList = $($ReturnObject.TempCatalogList)

    Write-Output "Calling AzureSignTool function to sign catalog list..."
    Use-AzureSignTool `
      -AzureKeyVaultUrl $AzureKeyVaultUrl `
      -CertificateName $CertificateName `
      -FileList $CatalogList

    Write-Output "Testing the catalog file..."
    Test-ScubaCatalogFile `
      -CatalogFilePath $CatalogFilePath

    $Parameters = @{
      Path       = $ModuleDestinationPath
      Repository = $GalleryName
    }
    if ($GalleryName -eq 'PSGallery') {
      $Parameters.Add('NuGetApiKey', $NuGetApiKey)
    }

    Write-Output "The ScubaGear module will be published..."
    # The -Force parameter is only required if the new version is less than or equal to
    # the current version, which is typically only true when testing.
    Publish-Module @Parameters -Force
  }
  catch {
    Write-Error "An error occurred when publishing ScubaGear.  Exiting..."
    exit 1
  }
}

function Copy-ModuleToTempLocation {
  <#
    .DESCRIPTION
      Copies the module source path to a temp location, keeping the name of the leaf folder the same.
      Throws an error if the copy fails.
      Returns the module destination path.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $ModuleSourcePath,
    [Parameter(Mandatory = $true)]
    [string]
    $ModuleTempPath
 )

  $Leaf = Split-Path -Path $ModuleSourcePath -Leaf
  $ModuleDestinationPath = Join-Path -Path $ModuleTempPath -ChildPath $Leaf

  Write-Warning "The module source path is $ModuleSourcePath"
  Write-Warning "The temp path is $ModuleTempPath"
  Write-Warning "The module destination path is $ModuleDestinationPath"

  # Remove the destination if it already exists
  if (Test-Path -Path $ModuleDestinationPath -PathType Container) {
    Remove-Item -Recurse -Force $ModuleDestinationPath
  }

  Write-Warning "Copying the module from source to dest..."

  Copy-Item $ModuleSourcePath -Destination $ModuleDestinationPath -Recurse

  # Verify that the destination exists
  if (Test-Path -Path $ModuleDestinationPath) {
    Write-Warning "The module destination path exists."
  }
  else {
    $ErrorMessage = "Failed to find the module destination path."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }

  return $ModuleDestinationPath
}

function Edit-ManifestFile {
  <#
    .DESCRIPTION
      Updates the manifest file in the module with info that PSGallery needs
      Throws an error if the manifest file cannot be found or updated.
      No return.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $ModuleDestinationPath,
    [Parameter(Mandatory = $false)]
    [string]
    $OverrideModuleVersion,
    [Parameter(Mandatory = $true)][AllowEmptyString()]
    [string]
    $PrereleaseTag
 )

  $ManifestFilePath = Join-Path -Path $ModuleDestinationPath -ChildPath "ScubaGear.psd1"

  Write-Warning "The manifest file path is $ManifestFilePath"

  # Verify that the manifest file exists
  if (Test-Path -Path $ManifestFilePath) {
    Write-Warning "The manifest file exists."
  }
  else {
    $ErrorMessage = "Failed to find the manifest file."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }

  # The module needs some version
  if ([string]::IsNullOrEmpty($OverrideModuleVersion)) {
    # If the override module version is missing, make up some version
    $CurrentModuleVersion = (Import-PowerShellDataFile $ManifestFilePath).ModuleVersion
    $TimeStamp = [int32](Get-Date -UFormat %s)
    $ModuleVersion = "$CurrentModuleVersion.$TimeStamp"
  }
  else {
    # Use what the user supplied
    $ModuleVersion = $OverrideModuleVersion
  }

  Write-Warning "The module version is $ModuleVersion"
  Write-Warning "The prerelease tag is $PrereleaseTag" # Can be empty

  $ProjectUri = "https://github.com/cisagov/ScubaGear"
  $LicenseUri = "https://github.com/cisagov/ScubaGear/blob/main/LICENSE"
  # Tags cannot contain spaces
  $Tags = 'CISA', 'O365', 'M365', 'AzureAD', 'Configuration', 'Exchange', 'Report', 'Security', 'SharePoint', 'Defender', 'Teams', 'PowerPlatform', 'OneDrive'

  # Configure the update parameters for the manifest file
  $ManifestUpdates = @{
    Path          = $ManifestFilePath
    ModuleVersion = $ModuleVersion
    ProjectUri    = $ProjectUri
    LicenseUri    = $LicenseUri
    Tags          = $Tags
  }
  if (-Not [string]::IsNullOrEmpty($PrereleaseTag)) {
    $ManifestUpdates.Add('Prerelease', $PrereleaseTag)
  }

  try {
    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    Update-ModuleManifest @ManifestUpdates
    $ErrorActionPreference = $CurrentErrorActionPreference
  }
  catch {
    Write-Warning "Error: Cannot edit the module because:"
    Write-Warning $_.Exception
    $ErrorMessage = "Failed to edit the module manifest."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }
  try {
    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    Test-ModuleManifest -Path $ManifestFilePath
    $ErrorActionPreference = $CurrentErrorActionPreference
  }
  catch {
    Write-Warning "Error: Cannot test the manifest file because:"
    Write-Warning $_.Exception
    $ErrorMessage = "Failed to test the manifest file."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }
}

function New-ArrayOfFilePaths {
  <#
    .DESCRIPTION
      Creates an array of the files to sign
      Throws an error if no matching files can be found.
      Returns the array.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $ModuleDestinationPath
 )

  $FileExtensions = "*.ps1", "*.psm1", "*.psd1"  # Array of extensions to match on
  $ArrayOfFilePaths = @()
  $ArrayOfFilePaths = Get-ChildItem -Recurse -Path $ModuleDestinationPath -Include $FileExtensions

  # Write-Warning "Verifying array of file paths..."
  # ForEach ($FilePath in $ArrayOfFilePaths) {
  #     Write-Warning ">>> File path is $FilePath"
  # }

  if ($ArrayOfFilePaths.Length -gt 0) {
    Write-Warning "Found $($ArrayOfFilePaths.Count) files to sign"
  }
  else {
    $ErrorMessage = "Failed to find any .ps1, .psm1, or .psd1 files."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }

  return $ArrayOfFilePaths
}

function New-FileList {
  <#
    .DESCRIPTION
      Creates a file that contains a list of all the files to sign
      Throws an error if the file is not created.
      Returns the name of the file.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [array]
    $ArrayOfFilePaths
 )
  $FileListPath = New-TemporaryFile
  $ArrayOfFilePaths.FullName | Out-File -FilePath $($FileListPath.FullName) -Encoding utf8 -Force
  $FileListFileName = $FileListPath.FullName

  # Verify that the file exists
  if (Test-Path -Path $FileListPath) {
    Write-Warning "The list file exists."
  }
  else {
    $ErrorMessage = "Failed to find the list file."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }

  return $FileListFileName
}

function Use-AzureSignTool {
  <#
    .DESCRIPTION
      AzureSignTool is a utility for signing code that is used to secure ScubaGear.
      https://github.com/vcsjones/AzureSignTool
      Throws an error if there was an error signing the files.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ [uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https' })]
    [System.Uri]
    $AzureKeyVaultUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CertificateName,
    [Parameter(Mandatory = $false)]
    [ValidateScript({ [uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http', 'https' })]
    $TimeStampServer = 'http://timestamp.digicert.com',
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    $FileList
  )

  Write-Warning "Using the AzureSignTool method..."

  $SignArguments = @(
    'sign',
    '-coe',
    '-fd', "sha256",
    '-tr', $TimeStampServer,
    '-kvu', $AzureKeyVaultUrl,
    '-kvc', $CertificateName,
    '-kvm'
    '-ifl', $FileList
  )

  Write-Warning "The files to sign are in the temp file $FileList"
  # Make sure the AzureSignTool can be called.
  # Get-Command returns a System.Management.Automation.ApplicationInfo object
  $NumberOfCommands = (Get-Command AzureSignTool) # Should return 1
  if ($NumberOfCommands -eq 0) {
    $ErrorMessage = "Failed to find the AzureSignTool on this system."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }
  $ToolPath = (Get-Command AzureSignTool).Path
  Write-Warning "The path to AzureSignTool is $ToolPath"
  # & is the call operator that executes a command, script, or function.
  $Results = & $ToolPath $SignArguments

  # Test the results for failures.
  # If there are no failures, the $SuccessPattern string will be the last
  # line in the results.
  # Warning: This is a brittle test, because it depends upon a specific string.
  $SuccessPattern = 'Failed operations: 0'
  $FoundNoFailures = $Results | Select-String -Pattern $SuccessPattern -Quiet
  if ($FoundNoFailures -eq $true) {
    Write-Warning "Signed the filelist without errors."
  }
  else {
    $ErrorMessage = "Failed to sign the filelist without errors."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }
}

function New-ScubaCatalogFile {
  <#
    .DESCRIPTION
      Creates a new catalog list file.
      Returns both the path to the catalog file and the temp
      file with the list of files that were signed.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $ModuleDestinationPath
  )

  $CatalogFileName = 'ScubaGear.cat'
  $CatalogFilePath = Join-Path -Path $ModuleDestinationPath -ChildPath $CatalogFileName

  if (Test-Path -Path $CatalogFilePath -PathType Leaf) {
    Remove-Item -Path $CatalogFilePath -Force
  }

  # New-FileCatlog creates a Windows catalog file (.cat) containing cryptographic hashes
  # for files and folders in the specified paths.
  $CatalogFilePath = New-FileCatalog -Path $ModuleDestinationPath -CatalogFilePath $CatalogFilePath -CatalogVersion 2.0
  Write-Warning "The catalog path is $CatalogFilePath"
  # The list of files that were signed.
  $CatalogList = New-TemporaryFile
  $CatalogFilePath.FullName | Out-File -FilePath $CatalogList -Encoding utf8 -Force

  # Return an object with the catalog file path and the temp file
  $ReturnObject = New-Object -TypeName PSObject
  $ReturnObject | Add-Member -MemberType NoteProperty -Name CatalogFilePath -Value $CatalogFilePath
  $ReturnObject | Add-Member -MemberType NoteProperty -Name TempCatalogList -Value $CatalogList
  return $ReturnObject
}

function Test-ScubaCatalogFile {
  <#
    .DESCRIPTION
      validates whether the hashes contained in a catalog file (.cat) matches
      the hashes of the actual files in order to validate their authenticity.
      Throws an error if the test fails.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $CatalogFilePath
  )

  $TestResult = Test-FileCatalog -Path $ModuleDestinationPath -CatalogFilePath $CatalogFilePath
  if ('Valid' -eq $TestResult) {
    Write-Warning "Signing the module was successful."
  }
  else {
    $ErrorMessage = "Signing the module was NOT successful."
    Write-Error = $ErrorMessage
    throw $ErrorMessage
  }
}