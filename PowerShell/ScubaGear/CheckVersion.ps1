
function Invoke-CheckScubaGearVersion {
    <#
    .SYNOPSIS
    Complain if a newer version of ScubaGear is available from the Github release page.

    .DESCRIPTION
    Checks latest version available on the github release page and compares it to the current running verison.
    #>
    $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $PSScriptRoot -ChildPath 'ScubaGear.psd1' -Resolve  -ErrorAction 'Stop' ) -ErrorAction 'Stop'
    $CurrentVersion = [System.Version]$ScubaManifest.ModuleVersion
    $LatestVersion = [System.Version]$(Invoke-RestMethod -Uri "https://api.github.com/repos/cisagov/ScubaGear/releases/latest" -ErrorAction 'Stop').tag_name.TrimStart("v")
    if ($CurrentVersion -lt $LatestVersion) {
        Write-Warning "A new version of ScubaGear ($latestVersion) is available. Please consider updating at: https://github.com/cisagov/ScubaGear/releases. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true before running ScubaGear."
    }
}

# Do the version check if the skip envvar is not defined.
if ([string]::IsNullOrWhiteSpace($env:SCUBAGEAR_SKIP_VERSION_CHECK)) {
    try {
        Invoke-CheckScubaGearVersion -ErrorAction 'Stop'
    }
    catch {
        Write-Warning "The ScubaGear version check failed to execute. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true.`n$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    }
}
