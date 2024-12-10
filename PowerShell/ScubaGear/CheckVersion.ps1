function Invoke-CheckScubaGearVersionPSGallery {
    # Define the path to the file where we store the last version check time
    $versionCheckFile = [System.IO.Path]::Combine($env:TEMP, "ScubaVersionCheck.txt")

    # Check if the version check file exists
    if (Test-Path $versionCheckFile) {
        # Read the last check time
        $lastCheckTime = Get-Content $versionCheckFile | Out-String
        $lastCheckTime = [datetime]::Parse($lastCheckTime)

        # If the last check was within 24 hours, skip the version check
        if ((Get-Date) -lt $lastCheckTime.AddHours(24)) {
            return  # Exit function without checking for a new version
        }
    }

    # Retrieve the installed version of ScubaGear from the system
    $installedModule = Get-Module -Name ScubaGear -ListAvailable
    if ($installedModule) {
        $currentVersion = [System.Version]$installedModule.Version
    } else {
        # If we are here, ScubaGear is not installed from PSGallery.
        return
    }

    # Retrieve the latest version from PowerShell Gallery
    $moduleInfo = Find-Module -Name ScubaGear
    $latestVersion = [System.Version]$moduleInfo.Version

    if ($currentVersion -lt $latestVersion) {
        Write-Warning "A new version of ScubaGear ($latestVersion) is available on PowerShell Gallery."
    }

    # Store the current time in the file to mark the last check time
    (Get-Date).ToString() | Set-Content $versionCheckFile
}


function Invoke-CheckScubaGearVersionGithub {
    $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $PSScriptRoot -ChildPath 'ScubaGear.psd1' -Resolve) -ErrorAction 'Stop'
    $CurrentVersion = $ScubaManifest.ModuleVersion
    $LatestVersion = $(Invoke-RestMethod -Uri "https://api.github.com/repos/cisagov/ScubaGear/releases/latest").tag_name.TrimStart("v")
    if ($CurrentVersion -ne $LatestVersion) {
            Write-Warning "A new version of ScubaGear ($latestVersion) is available. Please consider updating at: https://github.com/cisagov/ScubaGear/releases"
    }
}

# Do the version check if the skip envvar is not defined.
if ([string]::IsNullOrWhiteSpace($env:SCUBAGEAR_SKIP_VERSION_CHECK)) {
    Invoke-CheckScubaGearVersionPSGallery
    Invoke-CheckScubaGearVersionGithub
}
