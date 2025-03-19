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

    # Set the version of OPA defined in the config class.
    [ScubaConfig]::SetOpaVersion($LatestOpaVersion)

    # Update Acceptable Versions in Support Module
    $SupportModulePath = Join-Path -Path $RepoPath -ChildPath 'PowerShell/ScubaGear/Modules/Support/Support.psm1'
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
                "    '$CurrentOpaVersion', $LatestOpaVersion $END_VERSIONS_COMMENT" # 4 space indentation
            }
            elseif ($VersionsLength -eq 1) {
                # if the default version is the only acceptable version
                # Make `VariableName = CurrentVersion, DefaultOPAVer #EndVersionComment `
                $VersionsArr = $_ -split "="
                VersionsArr[0] + "= '$CurrentOpaVersion'" + ", $LatestOpaVersion $END_VERSIONS_COMMENT"
            }
            else {
                # No Splitting lines; Appending new Current OPA version to acceptable version
                $VersionsArr = $_ -split ","
                $NewVersions = ($VersionsArr[0..($VersionsArr.Length-2)] -join ",")
                $NewVersions + ", '$CurrentOpaVersion'" + ", $LatestOpaVersion $END_VERSIONS_COMMENT"
            }
        }
        else {
            $_
        }
    } | Set-Content $SupportModulePath
}

function New-OpaUpdatePr {
    <#
        .SYNOPSIS
            Creates a new PR with the changes
        .PARAMETER RepoPath
            Path to the repo
        .PARAMETER CurrentOpaVersion
            The old version in ScubaConfig that needs to be updated
        .PARAMETER LatestOpaVersion
            The new version in ScubaConfig used to update
        .PARAMETER OpaVersionBumpBranch
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath,
        [Parameter(Mandatory = $true)]
        [string]
        $CurrentOpaVersion,
        [Parameter(Mandatory = $true)]
        [string]
        $LatestOpaVersion,
        [Parameter(Mandatory = $true)]
        [string]
        $OpaVersionBumpBranch
    )

    # Create the PR Body
    $PRTemplatePath = Join-Path -Path $RepoPath -ChildPath '.github/pull_request_template.md'
    $Description = '<!-- Describe the "what" of your changes in detail. -->'
    $Motivation = '<!-- Why is this change required\? -->'
    $Testing = '<!-- see how your change affects other areas of the code, etc. -->'
    $RemoveHeader = '# <!-- Use the title to describe PR changes in the imperative mood --> #'
    $NewDescription = "- This pull request was created by a GitHub Action to bump ScubaGear's Open Policy Agent (OPA) executable version dependency.`n - Please fill out the rest of the template that the Action did not cover. `n"
    $NewMotivation = "- Bump to the latest OPA version v$($LatestOpaVersion) `n"
    $NewTesting = "- Currently a human should still check if bumping the OPA version affects ScubaGear.`n"

    $Body = "This is a test body fear me"
    $PrTemplateContent = (Get-Content -Path $PRTemplatePath) | ForEach-Object {
        $DescriptionRegex = $_ -match $Description
        $MotivationRegex = $_ -match $Motivation
        $TestingRegex = $_ -match $Testing
        $RemoveHeaderRegex = $_ -match $RemoveHeader # removes unneeded new line
        if ($DescriptionRegex) {
            $_ -replace $Description, $NewDescription
        }
        elseif ($MotivationRegex) {
            $_ -replace $Motivation, $NewMotivation
        }
        elseif ($TestingRegex) {
            $_ -replace $Testing, $NewTesting
        }
        elseif ($RemoveHeaderRegex) {
        $_ -replace $RemoveHeader, ""
        }
        else {
            $_ + "`n"
            }
    }
    git config --global user.email "action@github.com"
    git config --global user.name "GitHub Action"
    git checkout -b "$($OpaVersionBumpBranch)"
    git add .
    git commit -m "Bump OPA version from v$($CurrentOpaVersion) to  v$($LatestOpaVersion)"
    git push origin $OpaVersionBumpBranch
    gh pr create -B main -H $OpaVersionBumpBranch --title "Bump OPA version from v$($CurrentOpaVersion) to v$($LatestOpaVersion)" --body "${PrTemplateContent}" --label "version bump"
}