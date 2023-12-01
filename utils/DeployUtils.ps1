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
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GalleryName = 'PrivateScubaGearGallery',
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleVersion
    )

    $ModuleBuildPath = Build-ScubaModule -ModulePath $ModulePath -ModuleVersion $ModuleVersion

    Write-Host "Build Path: $ModuleBuildPath"

    if (SignScubaGearModule -ModulePath $ModuleBuildPath){
        Publish-Module -Path $ModuleBuildPath -Repository $GalleryName
    }
    else {
        Write-Error "Failed to sign module."
    }
}

function Build-ScubaModule{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ModulePath,
        [Parameter(Mandatory=$true)]
        [Version]
        $ModuleVersion
    )
    $Leaf = Split-Path -Path $ModulePath -Leaf
    $ModuleBuildPath = Join-Path -Path $env:TEMP -ChildPath $Leaf

    if (Test-Path -Path $ModuleBuildPath -PathType Container){
        Remove-Item -Recurse -Force $ModuleBuildPath
    }

    Copy-Item $ModulePath -Destination $env:TEMP -Recurse
    if (-not (ConfigureScubaGearModule -ModulePath $ModuleBuildPath -ModuleVersion $ModuleVersion)){
        Write-Error "Failed to configure scuba module for publishing."
    }

    return $ModuleBuildPath
}

function ConfigureScubaGearModule{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $ModulePath,
        [Parameter(Mandatory=$true)]
        [Version]
        $ModuleVersion
    )
    #TODO: Add any module configuration needed (e.g., adjust Module Version)
    $ManifestPath = Join-Path -Path $ModulePath -ChildPath "ScubaGear.psd1"
    $ManifestUpdates = @{
        Path = $ManifestPath
        ModuleVersion = $ModuleVersion
        ProjectUri = "https://github.com/cisagov/ScubaGear"
        LicenseUri = "https://github.com/cisagov/ScubaGear/blob/main/LICENSE"
        Tags = 'CISA', 'AzureAD', 'Cloud', 'Configuration', 'Exchange', 'Report', 'Security', 'SharePoint', 'Defender', 'Teams', 'PowerPlatform'
    }

    Update-ModuleManifest @ManifestUpdates

    Write-Debug "called ConfigureScubaGearModule with $ModulePath"
    return $true
}

function SignScubaGearModule{
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
    Write-Debug "called SignScubaGearModule with $ModulePath"
    $CatalogPath = Join-Path -Path $ModulePath -ChildPath "ScubaGear.cat"
    $Cert = Invoke-Command $GetCertificate
    Get-ChildItem $ModulePath -Include *.psd1,*psm1 -Recurse |
    Set-AuthenticodeSignature -Certificate $Cert -TimeStampServer $TimeStampServer -HashAlgorithm $HashAlgorithm
    New-FileCatalog -Path $ModulePath -CatalogFilePath $CatalogPath -CatalogVersion 2.0
    Get-ChildItem $CatalogPath -EA 0 |
    Set-AuthenticodeSignature -Certificate $Cert -TimestampServer $TimeStampServer -HashAlgorithm $HashAlgorithm

    $TestResult = Test-FileCatalog -CatalogFilePath $CatalogPath
    return 'Valid' -eq $TestResult.Status
}

function New-CodeSigningCertificate{
    New-SelfSignedCertificate -DnsName cisa.gov -Type CodeSigning -CertStoreLocation Cert:\CurrentUser\My
}

function GetCodeSigningCertificate{
    Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.HasPrivateKey -and ($_.NotAfter -gt (Get-Date))}
}

function IsRegistered{
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepoName = 'PrivateScubaGearGallery'
    )

#     Write-Debug "Looking for $RepoName local repository"

#     try{
#         $Repo = Get-PSRepository -Name $RepoName
#     }
#     catch {
#         Write-Error "In catch of IsRegistered"
#         return $false
#     }

#     return $null -ne $Repo
    return $false
}