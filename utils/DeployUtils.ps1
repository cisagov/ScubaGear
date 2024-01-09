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
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GalleryName = 'PrivateScubaGearGallery',
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $OverrideModuleVersion = ""
    )

    $ModuleBuildPath = Build-ScubaModule -ModulePath $ModulePath -OverrideModuleVersion $OverrideModuleVersion

    if (SignScubaGearModule -ModulePath $ModuleBuildPath){
        Publish-Module -Path $ModuleBuildPath -Repository $GalleryName
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
        $OverrideModuleVersion = ""
    )
    $Leaf = Split-Path -Path $ModulePath -Leaf
    $ModuleBuildPath = Join-Path -Path $env:TEMP -ChildPath $Leaf

    if (Test-Path -Path $ModuleBuildPath -PathType Container){
        Remove-Item -Recurse -Force $ModuleBuildPath
    }

    Copy-Item $ModulePath -Destination $env:TEMP -Recurse
    if (-not (ConfigureScubaGearModule -ModulePath $ModuleBuildPath -OverrideModuleVersion $OverrideModuleVersion)){
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
        $OverrideModuleVersion = ""
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
        Tags = 'CISA', 'AzureAD', 'Cloud', 'Configuration', 'Exchange', 'Report', 'Security', 'SharePoint', 'Defender', 'Teams', 'PowerPlatform'
    }

    Update-ModuleManifest @ManifestUpdates

    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $Result = Test-ModuleManifest -Path $ManifestPath
    $ErrorActionPreference = $CurrentErrorActionPreference

    return $null -ne $Result
}

function CreateFileList{
    param(
        [Parameter(Mandatry=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath,
        [Parameter(Mandatry=$false)]
        [AllowEmptyCollection()]
        [array]
        $Files = @(),
        [Parameter(Mandatry=$false)]
        [AllowEmptyCollection()]
        [array]
        $Extensions = @()
    )

    $Files = Get-ChildItem -Recurse -Path $SourcePath -Include $Extensions
    $Files += Get-ChildItem -Recurse -Path $SourcePath -Include $Files
    $FileList = New-TemporaryFile
    $Files.Path | Out-File -FilePath $FileList.Path -Encoding utf8 -Force
    return $FileList
}

function SignScubaGearModule{
    <#
        .NOTES
        Internal helper function
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(Mandatry=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(Mandatry=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $ClientId,
        [Parameter(Mandatry=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ClientSecret,
        [Parameter(Mandatry=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com'
    )
    $CatalogFileName = 'ScubaGear.cat'
    $CatalogPath = Join-Path -Path $ModulePath -ChildPath $CatalogFileName

    # Digitally sign scripts, manifest, and modules
    $FileList = CreateFileList -SourcePath $ModulePath -Extensions ".ps1,.psm1,.psd1" -OutputFileList $FileList

    $SignArguments = @(
        'sign',
        '-coe',
        '-v',
        '-fd',"sha256",
        '-kvu',$AzureKeyVaultUrl,
        '-kvi',$ClientId,
        '-kvt',$TenantId, 
        '-kvs',$ClientSecret,
        '-kvc',$CertificateName,
        '-ifl',$FileList         
    )
    Start-CodeSign `
        -AzureKeyVaultUrl $AzureKeyVaultUrl `
        -AzureKeyVaultClientId $ClientId `
        -AzureKeyValutClientSecret $ClientSecret `
        -AzureKeyVaultTenantId $TenantId `
        -AzureKeyVaultCertificate $CertificateName `
        -InputFileList $FileList `
        -TimestampUtl $TimeStampServer

    $ToolPath = (Get-Command AzureSignTool).Path    
    powershell -Command "& $ToolPath $SignArguments"    

    # Create and sign catalog    
    New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogPath -CatalogVersion 2.0 -Verbose
    $CatalogList = CreateFileList -SourcePath $ModulePath -Files @($CatalogPath) -OutputFileList $FileList

    $SignArguments = @(
        'sign',
        '-coe',
        '-v',
        '-fd',"sha256",
        '-kvu',$AzureKeyVaultUrl,
        '-kvi',$ClientId,
        '-kvt',$TenantId, 
        '-kvs',$ClientSecret,
        '-kvc',$CertificateName,
        '-ifl',$CatalogList        
    )
    
    $TestResult = Test-FileCatalog -CatalogFilePath $CatalogPath
    return 'Valid' -eq $TestResult.Status
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