#Requires -Version 5.1

function New-PrivateGallery {
    <#
    .Description
    Creates a new private package repository (i.e., gallery) on local file system
    .Parameter GalleryPath
    Path for directory to use for private gallery
    .Parameter GalleryName
    Name of the private gallery
    .Parameter Trusted
    Indicates if private gallery is registered as a trusted gallery
    .Example
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

    $GalleryPath = Join-Path -Path $GalleryRootPath -ChildPath $GalleryName
    if (Test-Path $GalleryPath) {
        Write-Debug "Removing private gallery at $GalleryPath"
        Remove-Item -Recursive -Force $GalleryPath
    }

    New-Item -Path $GalleryPath -ItemType Directory

    if (-not (IsRegistered -RepoName $GalleryName)) {
        Write-Debug "Attempting to register $GalleryName repository"

        $Splat = @{
            Name               = $GalleryName
            SourceLocation     = $GalleryPath
            PublishLocation    = $GalleryPath
            InstallationPolicy = if ($Trusted) { 'Trusted' } else { 'Untrusted' }
        }

        Register-PSRepository @Splat
    }
    else {
        Write-Warning "$GalleryName is already registered. You can unregister: `nUnregister-PSRepository -Name $GalleryName"
    }
}

function IsRegistered {
    <#
    .NOTES
    Internal helper function
    #>
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepoName = 'PrivateScubaGearGallery'
    )

    Write-Debug "Looking for $RepoName local repository"
    $Registered = $false
    try {
        $Registered = (Get-PSRepository).Name -contains $RepoName
    }
    catch {
        Write-Error "Failed to check IsRegistered: $_"
    }
    return $Registered
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
        $ModulePath,
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

    Write-Host "> Publishing ScubaGear module..."
    $ModuleBuildPath = Build-ScubaModule -ModulePath $ModulePath -OverrideModuleVersion $OverrideModuleVersion -PrereleaseTag $PrereleaseTag

    Write-Host "> Calling SignScubaGearModule function with..."
    Write-Host "> AzureKeyVaultUrl: $AzureKeyVaultUrl"
    Write-Host "> CertificateName: $CertificateName"
    Write-Host "> ModulePath: $ModuleBuildPath"
    $SuccessfullySigned = SignScubaGearModule `
        -AzureKeyVaultUrl $AzureKeyVaultUrl `
        -CertificateName $CertificateName `
        -ModulePath $ModuleBuildPath

    if ($SuccessfullySigned) {
        Write-Host "> The ScubaGear module was succesfully signed."
        $Parameters = @{
            Path       = $ModuleBuildPath
            Repository = $GalleryName
        }
        if ($GalleryName -eq 'PSGallery') {
            $Parameters.Add('NuGetApiKey', $NuGetApiKey)
        }

        Write-Host "> The ScubaGear module will be published."
        # TODO Uncomment this to actually publish
        # Publish-Module @Parameters
    }
    else {
        Write-Host "> The ScubaGear module was not succesfully signed."
        Write-Error "> Failed to sign module."
    }
}

function Build-ScubaModule {
    <#
    .NOTES
    Internal helper function
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $ModulePath,
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = "",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PrereleaseTag = ""
    )
    Write-Host ">> Building ScubaGear module..."

    $Leaf = Split-Path -Path $ModulePath -Leaf
    $ModuleBuildPath = Join-Path -Path $env:TEMP -ChildPath $Leaf

    if (Test-Path -Path $ModuleBuildPath -PathType Container) {
        Remove-Item -Recurse -Force $ModuleBuildPath
    }

    Copy-Item $ModulePath -Destination $env:TEMP -Recurse
    if (-not (ConfigureScubaGearModule -ModulePath $ModuleBuildPath -OverrideModuleVersion $OverrideModuleVersion -PrereleaseTag $PrereleaseTag)) {
        Write-Error ">> Failed to configure scuba module for publishing."
    }

    return $ModuleBuildPath
}

function ConfigureScubaGearModule {
    <#
    .NOTES
    Internal helper function
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $ModulePath,
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = "",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $PrereleaseTag = ""
    )
    Write-Host ">>> Configuring ScubaGear module..."
    #TODO: Add any module configuration needed (e.g., adjust Module Version)

    # Verify that the module path folder exists
    if (Test-Path -Path $ModulePath) {
        Write-Host ">>> The module dir exists at $ModulePath"
    }
    else {
        Write-Warning ">>> The module dir does not exist at $ModulePat"
        Write-Error ">>> Failing..."
    }

    $ManifestPath = Join-Path -Path $ModulePath -ChildPath "ScubaGear.psd1"

    # Verify that the manifest file exists
    if (Test-Path -Path $ManifestPath) {
        Write-Host ">>> The manifest file exists at $ManifestPath"
    }
    else {
        Write-Warning ">>> The manifest file does not exist at $ManifestPath"
        Write-Error ">>> Failing..."
    }

    $ModuleVersion = $OverrideModuleVersion

    if ([string]::IsNullOrEmpty($OverrideModuleVersion)) {
        $CurrentModuleVersion = (Import-PowerShellDataFile $ManifestPath).ModuleVersion
        $TimeStamp = [int32](Get-Date -UFormat %s)
        $ModuleVersion = "$CurrentModuleVersion.$TimeStamp"
    }

    Write-Host ">>> The prerelease tag is $PrereleaseTag"
    Write-Host ">>> The module version is $ModuleVersion"

    $ProjectUri = "https://github.com/cisagov/ScubaGear"
    $LicenseUri = "https://github.com/cisagov/ScubaGear/blob/main/LICENSE"
    # Tags cannot contain spaces
    $Tags = 'CISA', 'O365', 'M365', 'AzureAD', 'Configuration', 'Exchange', 'Report', 'Security', 'SharePoint', 'Defender', 'Teams', 'PowerPlatform', 'OneDrive'

    $ManifestUpdates = @{
        Path          = $ManifestPath
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
        Write-Warning ">>> Error: Cannot update module manifest:"
        Write-Warning ">>> Stacktrace:"
        Write-Warning $_.ScriptStackTrace
        Write-Warning ">>> Exception:"
        Write-Warning $_.Exception
        Write-Error ">>> Failed to update module manifest"
        return $False
    }
    try {
        $CurrentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        Test-ModuleManifest -Path $ManifestPath
        $ErrorActionPreference = $CurrentErrorActionPreference
    }
    catch {
        Write-Warning ">>> Warning: Cannot test module manifest:"
        Write-Warning ">>> Stacktrace:"
        Write-Warning $_.ScriptStackTrace
        Write-Warning ">>> Exception:"
        Write-Warning $_.Exception
        Write-Error ">>> Failed to test module manifest"
        return $False
    }

    # True indicates that the updating and testing were successful.
    return $True
}

function SignScubaGearModule {
    <#
    .SYNOPSIS
    Code sign the specified module
    .Description
    This function individually signs PowerShell artifacts (i.e., *.ps1, *.pms1) and creates a
    signed catalog of the entire module using a certificate housed in an Azure key vault.
    .Parameter AzureKeyVaultUrl
    The URL of the key vault with the code signing certificate
    .Parameter CertificateName
    The name of the code signing certificate
    .Parameter ModulePath
    The root path of the module to be signed
    .Parameter TimeStampServer
    Time server to use to timestamp the artifacts
    .NOTES
    There appears to be limited or at least difficult to find documentation on how to properly sign a PowerShell
    module to be published to PSGallery.
    https://learn.microsoft.com/en-us/powershell/gallery/concepts/publishing-guidelines?view=powershellget-3.x show
    general guidance.

    There is anecdotal evidence to sign all PowerShell artifacts (ps1, psm1, and pdsd1) in additional to a signed catalog For example,
    Microsoft.PowerApps.PowerShell (v1.0.34) and see both *.psd1 and *.psm1 files are signed and a catalog provided.

    There are a number of Non-authoritive references such as below showing all ps1, psm1, and psd1 being signed first then cataloged.
    https://github.com/dell/OpenManage-PowerShell-Modules/blob/main/Sign-Module.ps1
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
        $ModulePath,
        [Parameter(Mandatory = $false)]
        [ValidateScript({ [uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http', 'https' })]
        $TimeStampServer = 'http://timestamp.digicert.com'
    )

    Write-Host ">> Signing ScubaGear module..."

    # Sign scripts, manifest, and modules
    $ArrayOfFilePaths = CreateArrayOfFilePaths `
        -SourcePath $ModulePath `
        -Extensions "*.ps1", "*.psm1", "*.psd1"  # Array of extensions
    $FileList = CreateFileList $ArrayOfFilePaths
    Write-Host ">> The file list is $FileList"
    Write-Host ">> The contents of the file list are:"
    $FileListType = $FileList.GetType().fullname
    Write-Host ">> The type of file list is $FileListType"
    Write-Host $FileList
    Write-Host ">> Calling CallAzureSignTool function to sign scripts, manifest, and modules..."
    CallAzureSignTool `
        -AzureKeyVaultUrl $AzureKeyVaultUrl `
        -CertificateName $CertificateName `
        -TimeStampServer $TimeStampServer `
        -FileList $FileList

    # Create and sign catalog
    $CatalogFileName = 'ScubaGear.cat'
    $CatalogFilePath = Join-Path -Path $ModulePath -ChildPath $CatalogFileName

    if (Test-Path -Path $CatalogFilePath -PathType Leaf) {
        Remove-Item -Path $CatalogFilePath -Force
    }

    # New-FileCatlog creates a Windows catalog file (.cat) containing cryptographic hashes 
    # for files and folders in the specified paths.
    $CatalogFilePath = New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogFilePath -CatalogVersion 2.0
    Write-Host ">> The catalog path is $CatalogFilePath"
    $CatalogList = New-TemporaryFile
    $CatalogFilePath.FullName | Out-File -FilePath $CatalogList -Encoding utf8 -Force

    Write-Host ">> Calling CallAzureSignTool function to sign catalog list..."
    CallAzureSignTool `
        -AzureKeyVaultUrl $AzureKeyVaultUrl `
        -CertificateName $CertificateName `
        -TimeStampServer $TimeStampServer `
        -FileList $CatalogList

    # Test-FileCatalog validates whether the hashes contained in a catalog file (.cat) matches 
    # the hashes of the actual files in order to validate their authenticity.
    # Signing tool says it was successful, but the test says it was not.
    Write-Host ">> Testing the catalog"
    # There's no -Path parameter.
    $TestResult = Test-FileCatalog -CatalogFilePath $CatalogFilePath -Path $ArrayOfFilePaths[0] -Detailed
    # $TestResult = Test-FileCatalog -CatalogFilePath $CatalogFilePath -Path $ModulePath -Detailed
    Write-Host "Test result is $TestResult"

    # ForEach ($File in $FileList) {
    #     Write-Host $File
    # }
    if ($TestResult -eq 'Valid') {
        Write-Host ">> Signing the module was successful."
        return True
    }
    else {
        Write-Host ">> Signing the module was NOT successful."
        return False
    }
    return False
}

function CreateArrayOfFilePaths {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath,
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [array]
        $Extensions = @()
    )
    Write-Host ">>> Create array of file paths..."
    $ArrayOfFilePaths = @()
    if ($Extensions.Count -gt 0) {
        $FilePath = Get-ChildItem -Recurse -Path $SourcePath -Include $Extensions
        $ArrayOfFilePaths += $FilePath
    }
    ForEach ($FilePath in $ArrayOfFilePaths) {
        Write-Host ">>> File path is $FilePath"
    }
    return $ArrayOfFilePaths
}

function CreateFileList {
    <#
    .NOTES
    Internal function
    Creates a temp file with a list of filenames
    #>
    param($FileNames)
    Write-Host ">>> Creating file list..."
    Write-Host ">>> Found $($FileNames.Count) files to sign"
    $FileList = New-TemporaryFile
    $FileNames.FullName | Out-File -FilePath $($FileList.FullName) -Encoding utf8 -Force
    # $ContentOfFileList = $(Get-Content $FileList) # String
    return $FileList.FullName
}

function CallAzureSignTool {
    <#
    .NOTES
    Internal function
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

    Write-Host ">>> Running the AzureSignTool method..."

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

    Write-Host ">>> The file list is $FileList"
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Host ">>> The tool path is $ToolPath"
    $Results = & $ToolPath $SignArguments
    # Write-Host ">>> Results"
    # Write-Host $Results
}