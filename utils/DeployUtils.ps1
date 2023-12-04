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

function SignScubaGearModule{
    <#
        .NOTES
        Internal helper function
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [scriptblock]
        $GetCertificate = $function:GetCodeSigningCertificate,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com',
        [Parameter(Mandatory=$false)]
        [ValidateSet('SHA256')]
        [string]
        $HashAlgorithm = 'SHA256'
    )
    #TODO: Add code signing
    $CatalogFileName = 'ScubaGear.cat'
    $CatalogPath = Join-Path -Path $ModulePath -ChildPath $CatalogFileName
    $Cert = Invoke-Command $GetCertificate

    # Digitally sign scripts, manifest, and modules
    Get-ChildItem $ModulePath -Include *.psd1,*psm1,*.ps1 -Recurse |
    Set-AuthenticodeSignature -Certificate $Cert -TimeStampServer $TimeStampServer -HashAlgorithm $HashAlgorithm

    New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogPath -CatalogVersion 2.0 -Verbose
    Set-AuthenticodeSignature -FilePath $CatalogPath -Certificate $Cert -TimestampServer $TimeStampServer -HashAlgorithm $HashAlgorithm

    $TestResult = Test-FileCatalog -CatalogFilePath $CatalogPath
    return 'Valid' -eq $TestResult.Status
}

function New-CodeSigningCertificate{
    <#
        .NOTES
        Internal helper function
    #>
    New-SelfSignedCertificate -DnsName cisa.gov -Type CodeSigning -CertStoreLocation Cert:\CurrentUser\My
}

function GetCodeSigningCertificate{
    <#
        .NOTES
        Internal helper function
    #>
    #TODO:  Replace with official signing certificate
    Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.HasPrivateKey -and ($_.NotAfter -gt (Get-Date))}
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