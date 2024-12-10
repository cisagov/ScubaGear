function Invoke-CheckScubaGearVersionPSGallery {
    param (
        [bool]$DisableVersionCheck = $false
    )

    # Define the path to the file where we store the last version check time
    $versionCheckFile = [System.IO.Path]::Combine($env:TEMP, "ScubaVersionCheck.txt")

    # Check if version checking is disabled
    if ($DisableVersionCheck) {
        return
    }

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


function Invoke-CheckScubaGearVersionGit {
    # Check if git is available
    $gitAvailable = Get-Command git -ErrorAction SilentlyContinue

    if ($gitAvailable) {
        $scubaGearPath = "."

        if (Test-Path $scubaGearPath) {
            # Check if it's a git repo
            Set-Location -Path $scubaGearPath
            try {
                $gitTag = git describe --exact-match --tags 2>$null
            } catch {
                if ($_.Exception.Message -match "No names found, cannot describe anything") {
                    # If we are here, this checkout has no tags. May be a shallow clone used for the test runner.
                    return
                }
            }
            if ($gitTag) {
                # Remove leading "v" from the tag
                $currentVersion = $gitTag.TrimStart("v")

                # Fetch the latest release info from GitHub API
                $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/cisagov/ScubaGear/releases/latest"
                $latestVersion = $latestRelease.tag_name.TrimStart("v")

                # Compare the versions
                if ([System.Version]$currentVersion -lt [System.Version]$latestVersion) {
                    Write-Warning "A new version of ScubaGear ($latestVersion) is available. Please consider updating at: https://github.com/cisagov/ScubaGear/releases"
                }
            }
            else {
                # If we are here, the command is not running inside a git repo. Probably not installed from git.
                Write-Warning "ScubaGear is not currently at a GitHub tagged release. Consider using the latest tagged release. You can disable this warning using the SCUBAGEAR_SKIP_VERSION_CHECK environment variable."
            }
        }
    }
    else {
        # No git executable available. If we are here, ScubaGear was probably not installed from git.
        return
    }
}

# Do the version check if the skip envvar is not defined.
if ([string]::IsNullOrWhiteSpace($env:SCUBAGEAR_SKIP_VERSION_CHECK)) {
    Invoke-CheckScubaGearVersionPSGallery
    Invoke-CheckScubaGearVersionGit
}
