function Copy-ScubaBaselineDocument {
    <#
    .SYNOPSIS
    Execute the SCuBAGear tool security baselines for specified M365 products.
    .Description
    This is the main function that runs the Providers, Rego, and Report creation all in one PowerShell script call.
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

    @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint") | ForEach-Object {
        $SourceFileName = Join-Path -Path $PSScriptRoot -ChildPath "..\..\baselines\$_.md"
        $TargetFileName = Join-Path -Path $Destination -ChildPath "$_.md"
        Copy-Item -Path $SourceFileName -Destination $Destination -Force:$Force -ErrorAction Stop  2> $null
        Set-ItemProperty -Path $TargetFileName -Name IsReadOnly -Value $true
    }
}

Export-ModuleMember -Function @(
    'Copy-ScubaBaselineDocument'
)