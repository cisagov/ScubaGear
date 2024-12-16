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
    $ReleaseVersion
	)

  Write-Warning "Signing the module with AzureSignTool..."
  
  # Source the deploy utilities so the functions in it can be called.
  . Publish-ScubaGear.ps1
  
  # Remove non-release files
  Remove-Item -Recurse -Force repo -Include .git*
  Write-Warning "Creating an array of the files to sign..."
  $ArrayOfFilePaths = New-ArrayOfFilePaths `
    -ModuleDestinationPath repo
  
  Write-Warning "Creating a file with a list of the files to sign..."
  $FileListFileName = New-FileList `
    -ArrayOfFilePaths $ArrayOfFilePaths
  
  Write-Warning "Calling AzureSignTool function to sign scripts, manifest, and modules..."
  Use-AzureSignTool `
    -AzureKeyVaultUrl $AzureKeyVaultUrl `
    -CertificateName $CertificateName `
    -FileList $FileListFileName
  Move-Item  -Path repo -Destination "ScubaGear-$ReleaseVersion" -Force
  Compress-Archive -Path "ScubaGear-$ReleaseVersion" -DestinationPath "ScubaGear-$ReleaseVersion.zip"
}