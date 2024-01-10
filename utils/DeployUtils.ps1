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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath,
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [array]
        $Files = @(),
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [array]
        $Extensions = @()
    )

    if ($Extensions.Count -gt 0){
        $FileNames = Get-ChildItem -Recurse -Path $SourcePath -Include $Extensions
    }
    
    if ($Files.Count -gt 0){
        $FileNames += Get-ChildItem -Recurse -Path $SourcePath -Include $Files
    }
    
    Write-Debug "Found $($FileNames.Count) files to sign" 
    $FileList = New-TemporaryFile
    $FileNames.FullName | Out-File -FilePath $($FileList.FullName) -Encoding utf8 -Force
    return $FileList
}

function CallAzureSignTool{
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
        [ValidateScript({Test-Path -Path $_})]
        $ModulePath,
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
        '-kvu',$AzureKeyVaultUrl,
        '-kvc',$CertificateName,
        '-ifl',$FileList         
    )

    if ($PSCmdlet.ParameterSetName -eq 'ManagedIdentity'){
        $SignArguments += @(
            '-kvm',$true
        )
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal'){
        $SignArguments += @(
            '-kvi',$ClientId,
            '-kvt',$TenantId, 
            '-kvs',$ClientSecret
        )
    }
    else {
        Write-Error "Unexpected Credentials used."
    }

    $ToolPath = (Get-Command AzureSignTool).Path  
    Write-Debug "AzureSignTool path is $ToolPath"
    Write-Debug "Args: $SignArguments[0]"
    powershell -Command "& $ToolPath $SignArguments"      
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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
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
    $FileList = CreateFileList -SourcePath $ModulePath -Extensions "*.ps1","*.psm1","*.psd1"

    CallAzureSignTool @PSBoundParameters -FileList $FileList

    # Create and sign catalog
    if (Test-Path $CatalogPath){
        Remove-Item -Path $CatalogPath -Force
    }    

    New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogPath -CatalogVersion 2.0
    $CatalogList = CreateFileList -SourcePath $ModulePath -Files @($CatalogPath)

    CallAzureSignTool @PSBoundParameters -FileList $CatalogList

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
