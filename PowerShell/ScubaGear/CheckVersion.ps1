
function Invoke-CheckScubaGearVersion {
    <#
    .SYNOPSIS
    Complain if a newer version of ScubaGear is available from PSGallery.

    .DESCRIPTION
    Checks latest version available on PSGallery and compares it to the current running version.
    #>
    try{
        $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $PSScriptRoot -ChildPath 'ScubaGear.psd1' -Resolve  -ErrorAction 'Stop' ) -ErrorAction 'Stop'
        $CurrentVersion = [System.Version]$ScubaManifest.ModuleVersion
        $LatestVersion = [System.Version](Find-Module -Name ScubaGear -Repository PSGallery -ErrorAction SilentlyContinue).Version

        if ($null -ne $LatestVersion -and $CurrentVersion -lt $LatestVersion) {
            Write-Warning "A newer version of ScubaGear ($LatestVersion) is available. Please consider running: Update-ScubaGear, this notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true before running ScubaGear."
        }
    }
    catch{
        Write-Warning "The ScubaGear version check failed: $($_.Exception.Message)"
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
