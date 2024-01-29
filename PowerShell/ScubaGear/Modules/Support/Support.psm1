function Copy-ScubaBaselineDocument {
    <#
    .SYNOPSIS
    Copy security baselines documents to a user specified location.
    .Description
    This function makes copies of the security baseline documents included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the baselines. Defaults to <user home>\ScubaGear\baselines
    .Example
    Copy-ScubaBaselineDocument
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $Destination = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    if (-not (Test-Path -Path $Destination -PathType Container)){
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    @("teams", "exo", "defender", "aad", "powerbi", "powerplatform", "sharepoint") | ForEach-Object {
        $SourceFileName = Join-Path -Path $PSScriptRoot -ChildPath "..\..\baselines\$_.md"
        $TargetFileName = Join-Path -Path $Destination -ChildPath "$_.md"
        Copy-Item -Path $SourceFileName -Destination $Destination -Force:$Force -ErrorAction Stop  2> $null
        Set-ItemProperty -Path $TargetFileName -Name IsReadOnly -Value $true
    }
}

function Copy-ScubaSampleReport {
    <#
    .SYNOPSIS
    Copy sample reports to user defined location.
    .Description
    This function makes copies of the sample reports included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\reports
    .Example
    Copy-ScubaSampleReport
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/reports"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    $SourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Sample-Reports\"
    Copy-ScubaModuleFile -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -Force:$Force
}

function Copy-ScubaSampleConfigFile {
    <#
    .SYNOPSIS
    Copy sample configuration files to user defined location.
    .Description
    This function makes copies of the sample configuration files included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\config-files
    .Example
    Copy-ScubaSampleConfigFile
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    $SourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Sample-Config-Files\"
    Copy-ScubaModuleFile -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -Force:$Force
}

function Copy-ScubaModuleFile {
    <#
    .SYNOPSIS
    Copy Scuba module files (read-only) to user defined location.
    .Description
    This function makes copies of files included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the files.
    .Example
    Copy-ScubaModuleFile =Destination SomeWhere
    .Functionality
    Private
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $SourceDirectory,
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory,
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    if (-not (Test-Path -Path $DestinationDirectory -PathType Container)){
        New-Item -ItemType Directory -Path $DestinationDirectory | Out-Null
    }

    try {
        Get-ChildItem -Path $SourceDirectory | Copy-Item -Destination $DestinationDirectory -Recurse -Container -Force:$Force -ErrorAction Stop 2> $null
        Get-ChildItem -Path $DestinationDirectory -File -Recurse | ForEach-Object {$_.IsReadOnly = $true}
    }
    catch {
        throw "Scuba copy module files failed."
    }
}

Export-ModuleMember -Function @(
    'Copy-ScubaBaselineDocument',
    'Copy-ScubaSampleReport',
    'Copy-ScubaSampleConfigFile'
)
