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
    [CmdletBinding(DefaultParameterSetName='ManagedIdentity')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $ClientId,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ClientSecret,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com',
        [Parameter(Mandatory=$false, ParameterSetName = 'ManagedIdentity')]
        [switch]
        $UseManagedIdentity,
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
    [CmdletBinding(DefaultParameterSetName='ManagedIdentity')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'https'})]
        [System.Uri]
        $AzureKeyVaultUrl,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateName,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $ClientId,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ClientSecret,
        [Parameter(Mandatory=$true, ParameterSetName = 'ServicePrincipal')]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        $ModulePath,
        [Parameter(Mandatory=$false)]
        [ValidateScript({[uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri] $_).Scheme -in 'http','https'})]
        $TimeStampServer = 'http://timestamp.digicert.com',
        [Parameter(Mandatory=$false, ParameterSetName = 'ManagedIdentity')]
        [switch]
        $UseManagedIdentity
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
# SIG # Begin signature block
# MIIFugYJKoZIhvcNAQcCoIIFqzCCBacCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAcxMbVvohURJla
# UPnhjCRaMW6HJ5XmYbAKqssGf9KMh6CCAy0wggMpMIICEaADAgECAhAb+gKPfqFf
# sUTnulp6jFEzMA0GCSqGSIb3DQEBCwUAMB0xGzAZBgNVBAMMEnNjdWJhZ2Vhci5j
# aXNhLmdvdjAeFw0yNDAxMDgxNDQzMzZaFw0yNTAxMDgxNTAzMzZaMB0xGzAZBgNV
# BAMMEnNjdWJhZ2Vhci5jaXNhLmdvdjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALE10sE9jb6S6Hd0wiS6G8jSGlQ1tnKThTA6gVDRLghrpuoScseOigW0
# KFkjE4cEdTwDEzyUxvE2QTj2lpcyqDJgTiysfpn6TNSmimNTqjpa4E4o/WQ0g9by
# EhhJolIpdKBX1yilHz5wq/4Mj03H3sqkiMtiq6bhr3TAFrIDBP9YMYsEpwEBW7m2
# Dp8dZNyv33mDw6F/VIhY2PhqtC6o4rQZCz+gRAFCuFF6D0HlysDeL6uM7LBu1HFo
# uJrEGyWBSq0jwWwa8RPXf5MrL4hXRS6gvlGwwuhWZVNNM8dPdOT6hkCSpZP/8Xd3
# 5ZPK2i0F2KONwYMip7hirloCV0XwNBUCAwEAAaNlMGMwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdEQQWMBSCEnNjdWJhZ2Vhci5jaXNh
# LmdvdjAdBgNVHQ4EFgQUKj3c8f+aaBhBR5q/CzA5P+GzYo8wDQYJKoZIhvcNAQEL
# BQADggEBAK7+sBDSCaVUd0YNUoU0Y9Plp8879mri1hXM2cxpCyvUrOEB0ej28ckp
# lRTA4n4oBIZ7x6p2ZH+XrQOcz+CzbjtuQ3u0nDAEr8bq8Z2kl8DuNS1b/nJKwgtT
# EaAhvPwDO3FXwS8Ohh/BmX84/zPbrPWfjyzAfjUnwRH8qy0xJc8mcjADiO5DcTEw
# B20Ev4G8FVwUuGDODWQsudwSeYUO02rqFqwIeI5anOO3fesj70blyatNNEVfrKih
# yvPDK4d9uSJD7Dvq3by5FtH1ooHihU0pNFphfLufg20bvLHpxJtMnR8v3V+UTs6G
# /hHUdnsmHZHpipFGj0+JJD2tig4T+BkxggHjMIIB3wIBATAxMB0xGzAZBgNVBAMM
# EnNjdWJhZ2Vhci5jaXNhLmdvdgIQG/oCj36hX7FE57paeoxRMzANBglghkgBZQME
# AgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCAT7MuwCf/BbJ+C0V7XsNsX9VjINf5F0GXBMAIwLbZrfzANBgkq
# hkiG9w0BAQEFAASCAQBAYl6vK/AjUgSK/HXWy7vsDw+GbAcsjOPrsJ4GkvpdJ5ye
# mKZ9XyMibM0lJ5J0chBW87+kpzk4qEwbIrBljPKXwmQqembhiXs4jkkwfjTu2zuq
# yP0W0cwO/3mZQhsQUA48+kU/YjJB3MjTa3adi360LeOF3yrRee1PQ4VQKBzmrMbW
# 82NHYFlJiI6hgMs2v4TBmGFWEbkiVN+PstYSzvOXFR9dv6wC/Q6FfVnCP5URIan6
# Z/YUyRMXXPx2HMgeJpPamtMDnTC3jdf4ZBOpCjf78j00IHwiZxKc15ljwyfeGFyO
# kHasj0RyK0oHjhA7l9g7RQSKgCjVENLX24VUePb/
# SIG # End signature block
