function Invoke-CheckScubaGearVersion {

    # Retrieve the installed version of ScubaGear from the system
    $InstalledModule = Get-Module -Name ScubaGear -ListAvailable -ErrorAction 'Stop'

    # If multiple different versions are installed, get the most recent.
    if ($InstalledModule -is [array]) {
        $InstalledModule = $InstalledModule | Sort-Object -Property Version | Select-Object -Last 1
    }

    # Check if no results found.
    if (!$InstalledModule) {
        # If we are here, ScubaGear is not installed from PSGallery.
        # Or it may have been installed a different way in a nonstandard folder,
        # or is running in an extracted release folder. Check github instead.
        return Invoke-CheckScubaGearVersionGithub -ErrorAction 'Stop'
    }

    $LatestInstalledVersion = [System.Version]$InstalledModule.Version

    # Retrieve the latest version from PowerShell Gallery
    $ModuleInfo = Find-Module -Name ScubaGear -ErrorAction 'Stop'
    $LatestPSGalleryVersion = [System.Version]$ModuleInfo.Version

    if ($LatestInstalledVersion -lt $LatestPSGalleryVersion) {
        Write-Warning "A newer version of ScubaGear ($LatestPSGalleryVersion) is available on PowerShell Gallery. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true before running ScubaGear."
    }
}


function Invoke-CheckScubaGearVersionGithub {
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
