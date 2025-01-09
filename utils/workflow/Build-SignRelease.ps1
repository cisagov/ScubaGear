function New-ModuleSignature {
  <#
    .SYNOPSIS
      Sign the ScubaGear module.
    .PARAMETER $AzureKeyVaultUrl
      The URL for the KeyVault in Azure.
    .PARAMETER $CertificateName
      The name of the certificate stored in the KeyVault.
    .PARAMETER $ReleaseVersion
      The version number of the release (e.g., 1.5.1).
    .PARAMETER $RootFolderName
      The name of the root folder.
    .EXCEPTIONS
      System.IO.DirectoryNotFoundException
        Thrown if $RootFolderName does not exist.
  #>
  [CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$AzureKeyVaultUrl,
		[Parameter(Mandatory = $true)]
		[string]
		$CertificateName,
    [Parameter(Mandatory = $true)]
    [string]
    $ReleaseVersion,
    [Parameter(Mandatory = $true)]
    [string]
    $RootFolderName
	)

  Write-Warning "Signing the module with AzureSignTool..."

  # Verify that $RootFolderName exists
  Write-Warning "The root folder name is $RootFolderName"
  if (Test-Path -Path $RootFolderName) {
    Write-Warning "Directory exists"
  } else {
    Write-Warning "Directory does not exist; throwing an exception..."
    throw [System.IO.DirectoryNotFoundException] "Directory not found: $RootFolderName"
  }

  # Source the deploy utilities so the functions in it can be called.
  $PublishPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\utils\workflow\Publish-ScubaGear.ps1' -Resolve
  . $PublishPath

  # Remove non-release files (required for non-Windows machines)
  # Delete git folder
  Remove-Item -Recurse -Force $RootFolderName -Include .git*
  Write-Warning "Creating an array of the files to sign..."
  $ArrayOfFilePaths = New-ArrayOfFilePaths `
    -ModuleDestinationPath $RootFolderName

  Write-Warning "Creating a file with a list of the files to sign..."
  $FileListFileName = New-FileList `
    -ArrayOfFilePaths $ArrayOfFilePaths

  Write-Warning "Calling AzureSignTool function to sign scripts, manifest, and modules..."
  Use-AzureSignTool `
    -AzureKeyVaultUrl $AzureKeyVaultUrl `
    -CertificateName $CertificateName `
    -FileList $FileListFileName
  Move-Item -Path $RootFolderName -Destination "ScubaGear-$ReleaseVersion" -Force
  Compress-Archive -Path "ScubaGear-$ReleaseVersion" -DestinationPath "ScubaGear-$ReleaseVersion.zip"
}
