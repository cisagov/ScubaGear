function Invoke-CheckScubaGearVersionPSGallery {

    # Retrieve the installed version of ScubaGear from the system
    $InstalledModule = Get-Module -Name ScubaGear -ListAvailable -ErrorAction 'Stop'
    if ($InstalledModule) {
        $CurrentVersion = [System.Version]$InstalledModule.Version
    } else {
        # If we are here, ScubaGear is not installed from PSGallery.
        # Or it may have been installed a different way in a nonstandard folder,
        # or is running in an extracted release folder. Check github instead.
        return Invoke-CheckScubaGearVersionGithub -ErrorAction 'Stop'
    }

    # Retrieve the latest version from PowerShell Gallery
    $ModuleInfo = Find-Module -Name ScubaGear -ErrorAction 'Stop'
    $LatestVersion = [System.Version]$ModuleInfo.Version

    if ($CurrentVersion -lt $LatestVersion) {
        Write-Warning "A new version of ScubaGear ($LatestVersion) is available on PowerShell Gallery. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true before running ScubaGear."

    }
}


function Invoke-CheckScubaGearVersionGithub {
    $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $PSScriptRoot -ChildPath 'ScubaGear.psd1' -Resolve  -ErrorAction 'Stop' ) -ErrorAction 'Stop'
    $CurrentVersion = $ScubaManifest.ModuleVersion
    $LatestVersion = $(Invoke-RestMethod -Uri "https://api.github.com/repos/cisagov/ScubaGear/releases/latest" -ErrorAction 'Stop').tag_name.TrimStart("v")
    if ($CurrentVersion -ne $LatestVersion) {
        Write-Warning "A new version of ScubaGear ($latestVersion) is available. Please consider updating at: https://github.com/cisagov/ScubaGear/releases. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true before running ScubaGear."
    }
}

# Do the version check if the skip envvar is not defined.
if ([string]::IsNullOrWhiteSpace($env:SCUBAGEAR_SKIP_VERSION_CHECK)) {
    try {
        Invoke-CheckScubaGearVersionPSGallery -ErrorAction 'Stop'
    }
    catch {
        Write-Warning "The ScubaGear version check failed to execute. This notification can be disabled by setting `$env:SCUBAGEAR_SKIP_VERSION_CHECK = `$true.`n$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    }
}
