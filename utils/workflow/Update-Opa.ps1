function Confirm-OpaUpdateRequirements {
    <#
        .SYNOPSIS
            Determine if OPA update is required
        .PARAMETER RepoPath
            Path to the repo
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )

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

    # Find our current OPA version using some dirty string manipulation
    $ScubaConfigPath = Join-Path -path $RepoPath PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1

    $OPAVerRegex = "\'\d+\.\d+\.\d+\'"
    $DefaultVersionPattern = "DefaultOPAVersion = $OPAVerRegex"
    $ScubaConfigModule = Get-Content $ScubaConfigPath -Raw
    $CurrentOPAVersion = '0.0.0'
    if ($ScubaConfigModule -match $DefaultVersionPattern) {
        $CurrentOPAVersion = ($Matches[0] -split "=")[1] -replace " ", ""
        $CurrentOPAVersion = $CurrentOPAVersion -replace "'", ""
    }
    if (($LatestOPAVersion -gt $CurrentOPAVersion) -and (-not $OPAVersionBranchExists)) {
        $UpdateRequired = $true
    }
    if ($UpdateRequired) {
        Write-Warning "OPA version update required."
    }
    else {
        Write-Warning "OPA version update is not required. Update branch already exists or OPA version is already up to date."
    }

    # Return values in a hashtable
    $ReturnValues = @{
        "LatestOPAVersion" = $LatestOPAVersion
        "OPAVersionBumpBranch" = $OPAVersionBumpBranch
        "UpdateRequired" = $UpdateRequired
        "CurrentOPAVersion" = $CurrentOPAVersion
    }
    return $ReturnValues
}

function Update-OpaVersion {
    <#
        .SYNOPSIS
            Update OPA version in ScubaGear
        .PARAMETER RepoPath
            Path to the repo
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )
    # Replace Default version in Config Module
    $ScubaConfigPath = Join-Path -path $RepoPath PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1
    $OPAVerRegex = "\'\d+\.\d+\.\d+\'"
    $DefaultVersionPattern = "DefaultOPAVersion = $OPAVerRegex"
    $ScubaConfigModule = Get-Content $ScubaConfigPath -Raw
    if ($ScubaConfigModule -match $DefaultVersionPattern) {
        $Content = $ScubaConfigModule -replace $DefaultVersionPattern, "DefaultOPAVersion = '$LatestOPAVersion'"
        Set-Content -Path $ScubaConfigPath -Value $Content -NoNewline
    }
    else {
        throw "Fatal Error: Couldn't find the default OPA version in the ScubaConfig."
    }

    # Update Acceptable Versions in Support Module
    $SupportModulePath = '.\PowerShell\ScubaGear\Modules\Support\Support.psm1'
    $MAXIMUM_VER_PER_LINE = 4 # Handle long lines of acceptable versions
    $END_VERSIONS_COMMENT = "# End Versions" # EOL comment in the PowerShell file
    $EndAcceptableVerRegex = ".*$END_VERSIONS_COMMENT"
    $DefaultOPAVersionVar = "[ScubaConfig]::ScubaDefault('DefaultOPAVersion')"

    (Get-Content -Path $SupportModulePath) | ForEach-Object {
        $EndAcceptableVarMatch = $_ -match $EndAcceptableVerRegex
        if ($EndAcceptableVarMatch) {
            $VersionsLength = ($_ -split ",").length

            # Split the line if we reach our version limit per line
            # in the the file. This is to prevent long lines.
            if ($VersionsLength -gt $MAXIMUM_VER_PER_LINE) {
                # Splitting lines; Current and latest OPA Version will start on the next line
                $VersionsArr = $_ -split ","
                # Create a new line
                # Then add the new version on the next line
                ($VersionsArr[0..($VersionsArr.Length-2)] -join ",") + ","
                "    '$CurrentOPAVersion', $DefaultOPAVersionVar $END_VERSIONS_COMMENT" # 4 space indentation
            }
            elseif ($VersionsLength -eq 1) {
                # if the default version is the only acceptable version
                # Make `VariableName = CurrentVersion, DefaultOPAVer #EndVersionComment `
                $VersionsArr = $_ -split "="
                $VersionsArr[0] + "= '$CurrentOPAVersion'" + ", $DefaultOPAVersionVar $END_VERSIONS_COMMENT"
            }
            else {
                # No Splitting lines; Appending new Current OPA version to acceptable version
                $VersionsArr = $_ -split ","
                $NewVersions = ($VersionsArr[0..($VersionsArr.Length-2)] -join ",")
                $NewVersions + ", '$CurrentOPAVersion'" + ", $DefaultOPAVersionVar $END_VERSIONS_COMMENT"
            }
        }
        else {
            $_
        }
    } | Set-Content $SupportModulePath
}