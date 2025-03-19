using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

function Confirm-OpaUpdateRequirements {
    <#
        .SYNOPSIS
            Determine if OPA update is required
    #>

    Write-Warning "Determining if OPA needs to be updated..."

    $UpdateRequired = $false
    # Get latest version via REST
    $LatestOPAVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/open-policy-agent/opa/releases/latest" | Select-Object -ExpandProperty tag_name
    $LatestOPAVersion = $LatestOPAVersion -replace "v", ""

    # Check if there is already an update branch
    $OPAVersionBumpBranch = "opa-version-bump-$($LatestOPAVersion)"
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='$Temp required to avoid having PS eat the return code from git.')]
    $Temp = git ls-remote --exit-code --heads origin $OPAVersionBumpBranch

    $OPAVersionBranchExists = $false
    if ($LASTEXITCODE -eq 0) {
        $OPAVersionBranchExists = $true
    }

    # Get the version of OPA defined in the config class.
    $CurrentOPAVersion = [ScubaConfig]::GetOpaVersion()

    # Check to see if updates are required, and if not, why not.
    if ($LatestOPAVersion -gt $CurrentOPAVersion) {
        if (-not $OPAVersionBranchExists) {
            Write-Warning "OPA version update required."
            $UpdateRequired = $true
        }
        else {
            Write-Warning "Update branch ($($OPAVersionBumpBranch)) already exists; no update required."
        }
    }
    else {
        Write-Warning "OPA version is already up to date; no update required."
    }

    # Return values in a hashtable
    $ReturnValues = @{
        "LatestOPAVersion" = $LatestOPAVersion
        "OPAVersionBumpBranch" = $OPAVersionBumpBranch
        "UpdateRequired" = $UpdateRequired
        "CurrentOPAVersion" = $CurrentOPAVersion
    }
    return $ReturnValues
    # Note that git-ls will always fail with exit code 1 when the
    # branch does not exist. Setting exit 0 (success) at the end
    # of this workflow to prevent that error.
    exit 0
}

function Update-OpaVersion {
    <#
        .SYNOPSIS
            Update OPA version in ScubaGear config file
        .PARAMETER RepoPath
            Path to the repo
        .PARAMETER CurrentOpaVersion
            The old version in ScubaConfig that needs to be updated
        .PARAMETER LatestOpaVersion
            The new version in ScubaConfig used to update
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath,
        [Parameter(Mandatory = $true)]
        [string]
        $CurrentOpaVersion,
        [Parameter(Mandatory = $true)]
        [string]
        $LatestOpaVersion
    )

    Write-Warning "Updating the version of OPA in ScubaConfig.psm1..."

    # Replace Default version in Config Module
    # Set the version of OPA defined in the config class.
    [ScubaConfig]::SetOpaVersion($CurrentOPAVersion)

    # $ScubaConfigPath = Join-Path -path $RepoPath PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1
    # $OPAVerRegex = "\'\d+\.\d+\.\d+\'"
    # $DefaultVersionPattern = "DefaultOPAVersion = $OPAVerRegex"
    # $ScubaConfigModule = Get-Content $ScubaConfigPath -Raw
    # if ($ScubaConfigModule -match $DefaultVersionPattern) {
    #     $Content = $ScubaConfigModule -replace $DefaultVersionPattern, "DefaultOPAVersion = '$LatestOpaVersion'"
    #     Set-Content -Path $ScubaConfigPath -Value $Content -NoNewline
    # }
    # else {
    #     throw "Fatal Error: Couldn't find the default OPA version in the ScubaConfig."
    # }

    Write-Warning "Done.."

    # # Update Acceptable Versions in Support Module
    # $SupportModulePath = '.\PowerShell\ScubaGear\Modules\Support\Support.psm1'
    # $MAXIMUM_VER_PER_LINE = 4 # Handle long lines of acceptable versions
    # $END_VERSIONS_COMMENT = "# End Versions" # EOL comment in the PowerShell file
    # $EndAcceptableVerRegex = ".*$END_VERSIONS_COMMENT"
    # $DefaultOPAVersionVar = "[ScubaConfig]::ScubaDefault('DefaultOPAVersion')"

    # (Get-Content -Path $SupportModulePath) | ForEach-Object {
    #     $EndAcceptableVarMatch = $_ -match $EndAcceptableVerRegex
    #     if ($EndAcceptableVarMatch) {
    #         $VersionsLength = ($_ -split ",").length

    #         # Split the line if we reach our version limit per line
    #         # in the the file. This is to prevent long lines.
    #         if ($VersionsLength -gt $MAXIMUM_VER_PER_LINE) {
    #             # Splitting lines; Current and latest OPA Version will start on the next line
    #             $VersionsArr = $_ -split ","
    #             # Create a new line
    #             # Then add the new version on the next line
    #             ($VersionsArr[0..($VersionsArr.Length-2)] -join ",") + ","
    #             "    '$CurrentOpaVersion', $DefaultOPAVersionVar $END_VERSIONS_COMMENT" # 4 space indentation
    #         }
    #         elseif ($VersionsLength -eq 1) {
    #             # if the default version is the only acceptable version
    #             # Make `VariableName = CurrentVersion, DefaultOPAVer #EndVersionComment `
    #             $VersionsArr = $_ -split "="
    #             $VersionsArr[0] + "= '$CurrentOpaVersion'" + ", $DefaultOPAVersionVar $END_VERSIONS_COMMENT"
    #         }
    #         else {
    #             # No Splitting lines; Appending new Current OPA version to acceptable version
    #             $VersionsArr = $_ -split ","
    #             $NewVersions = ($VersionsArr[0..($VersionsArr.Length-2)] -join ",")
    #             $NewVersions + ", '$CurrentOpaVersion'" + ", $DefaultOPAVersionVar $END_VERSIONS_COMMENT"
    #         }
    #     }
    #     else {
    #         $_
    #     }
    # } | Set-Content $SupportModulePath
}