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
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $GalleryRootPath = $env:TEMP,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GalleryName = 'PrivateScubaGearGallery',
        [switch]
        $Trusted
    )

    $GalleryPath = Join-Path -Path $GalleryRootPath -ChildPath $GalleryName
    if (Test-Path $GalleryPath){
        Write-Debug "Removing private gallery at $GalleryPath"
        Remove-Item -Recursive -Force $GalleryPath
    }

    New-Item -Path $GalleryPath -ItemType Directory

    if (-not (IsRegistered -RepoName $GalleryName)){
        Write-Debug "Attempting to register $GalleryName repository"

        $Splat = @{
            Name = $GalleryName
            SourceLocation = $GalleryPath
            PublishLocation = $GalleryPath
            InstallationPolicy = if ($Trusted) {'Trusted'} else {'Untrusted'}
        }

        Register-PSRepository @Splat
    }
    else {
        Write-Warning "$GalleryName is already registered. You can unregister: `nUnregister-PSRepository -Name $GalleryName"
    }
}

function Publish-ScubaGearModule{
    <#
    .Description
    Publish ScubaGear module to private package repository
    .Parameter ModulePath
    Path to module root directory
    .Parameter GalleryName
    Name of the private package repository (i.e., gallery)
    .Parameter OverrideModuleVersion
    Optional module version.  If provided it will use as module version. Otherwise, the current version from the manifest with a revision number is added instead.
    #>
    param (
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(ParameterSetName = 'PrivateGallery')]
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(ParameterSetName = 'PrivateGallery')]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(ParameterSetName = 'PrivateGallery')]
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ModulePath,
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(ParameterSetName = 'PrivateGallery')]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GalleryName = 'PrivateScubaGearGallery',
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(ParameterSetName = 'PrivateGallery')]
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = "",
        [Parameter(ParameterSetName = 'PublicGallery')]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NuGetApiKey
    )

    $ModuleBuildPath = Build-ScubaModule -ModulePath $ModulePath -OverrideModuleVersion $OverrideModuleVersion

    if (SignScubaGearModule -AzureKeyVaultUrl $AzureKeyVaultUrl -CertificateName $CertificateName -ModulePath $ModuleBuildPath){
        $PublishSplat = @{
            Path = $ModuleBuildPath
            Repository = $GalleryName
        }

        if ($PublicGallery){
            $PublishSplat.Add('NuGetApiKey', $NuGetApiKey)
        }

        Publish-Module @PublishSplat
    }
    else {
        Write-Error "Failed to sign module."
    }
}

function Build-ScubaModule{
    <#
    .NOTES
    Internal helper function
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = "",
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $PrereleaseTag = ""
    )
    $Leaf = Split-Path -Path $ModulePath -Leaf
    $ModuleBuildPath = Join-Path -Path $env:TEMP -ChildPath $Leaf

    if (Test-Path -Path $ModuleBuildPath -PathType Container){
        Remove-Item -Recurse -Force $ModuleBuildPath
    }

    Copy-Item $ModulePath -Destination $env:TEMP -Recurse
    if (-not (ConfigureScubaGearModule -ModulePath $ModuleBuildPath -OverrideModuleVersion $OverrideModuleVersion -PrereleaseTag $PrereleaseTag)){
        Write-Error "Failed to configure scuba module for publishing."
    }

    return $ModuleBuildPath
}

function ConfigureScubaGearModule{
    <#
    .NOTES
    Internal helper function
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = "",
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $PrereleaseTag = ""
    )
    #TODO: Add any module configuration needed (e.g., adjust Module Version)

    $ManifestPath = Join-Path -Path $ModulePath -ChildPath "ScubaGear.psd1"
    $ModuleVersion = $OverrideModuleVersion

    if ([string]::IsNullOrEmpty($OverrideModuleVersion)){
        $CurrentModuleVersion = (Import-PowerShellDataFile $ManifestPath).ModuleVersion
        $TimeStamp = [int32](Get-Date -UFormat %s)
        $ModuleVersion = "$CurrentModuleVersion.$TimeStamp"
    }

    $ManifestUpdates = @{
        Path = $ManifestPath
        ModuleVersion = $ModuleVersion
        ProjectUri = "https://github.com/cisagov/ScubaGear"
        LicenseUri = "https://github.com/cisagov/ScubaGear/blob/main/LICENSE"
        Tags = 'CISA', 'Microsoft 365', 'O365', 'Microsoft Entra Id', 'Configuration', 'Exchange', 'Report', 'Security', 'SharePoint', 'Defender', 'Teams', 'PowerPlatform', 'OneDrive'
    }

    if (-Not [string]::IsNullOrEmpty($PrereleaseTag)){
        $ManifestUpdates.Add('Prerelease', $PrereleaseTag)
    }

    try {
        Update-ModuleManifest @ManifestUpdates
        $CurrentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $Result = Test-ModuleManifest -Path $ManifestPath
        $ErrorActionPreference = $CurrentErrorActionPreference
    }
    catch {
        Write-Error "Manifest is not valid"
        $Result = $null
    }

    return $null -ne $Result
}

function CreateFileList{
    <#
    .NOTES
    Internal function
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath,
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [array]
        $Extensions = @()
    )

    $FileNames = @()

    if ($Extensions.Count -gt 0){
        $FileNames += Get-ChildItem -Recurse -Path $SourcePath -Include $Extensions
    }

    Write-Debug "Found $($FileNames.Count) files to sign"

    $FileList = New-TemporaryFile
    $FileNames.FullName | Out-File -FilePath $($FileList.FullName) -Encoding utf8 -Force
    Write-Debug "Files: $(Get-Content $FileList)"
    return $FileList.FullName
}

function CallAzureSignTool{
    <#
    .NOTES
    Internal function
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com',
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $FileList
    )

    $SignArguments = @(
        'sign',
        '-coe',
        '-fd',"sha256",
        '-tr', $TimeStampServer,
        '-kvu',$AzureKeyVaultUrl,
        '-kvc',$CertificateName,
        '-kvm'
        '-ifl',$FileList
    )

    Write-Debug "Calling AzureSignTool: $SignArguments"

    $ToolPath = (Get-Command AzureSignTool).Path
    & $ToolPath $SignArguments
}
function SignScubaGearModule{
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
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com'
    )


    # Digitally sign scripts, manifest, and modules
    $FileList = CreateFileList -SourcePath $ModulePath -Extensions "*.ps1","*.psm1","*.psd1"
    CallAzureSignTool `
      -AzureKeyVaultUrl $AzureKeyVaultUrl `
      -CertificateName $CertificateName `
      -TimeStampServer $TimeStampServer `
      -FileList $FileList

    # Create and sign catalog
    $CatalogFileName = 'ScubaGear.cat'
    $CatalogPath = Join-Path -Path $ModulePath -ChildPath $CatalogFileName

    if (Test-Path -Path $CatalogPath -PathType Leaf){
        Remove-Item -Path $CatalogPath -Force
    }

    $CatalogPath = New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogPath -CatalogVersion 2.0
    $CatalogList = New-TemporaryFile
    $CatalogPath.FullName | Out-File -FilePath $CatalogList -Encoding utf8 -Force

    CallAzureSignTool `
      -AzureKeyVaultUrl $AzureKeyVaultUrl `
      -CertificateName $CertificateName `
      -TimeStampServer $TimeStampServer `
      -FileList $CatalogList

    $TestResult = Test-FileCatalog -CatalogFilePath $CatalogPath
    return 'Valid' -eq $TestResult
}

function IsRegistered{
    <#
    .NOTES
    Internal helper function
    #>
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepoName = 'PrivateScubaGearGallery'
    )

    Write-Debug "Looking for $RepoName local repository"
    $Registered = $false

    try{
        $Registered = (Get-PSRepository).Name -contains $RepoName
    }
    catch {
        Write-Error "Failed to check IsRegistered: $_"
    }

    return $Registered
}
