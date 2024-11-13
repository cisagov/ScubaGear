function Set-ScubaGearVersionManifest {
    <#
    .Description
    Replace ScubaGear module version in the ScubaGear.psd1 manifest.
    .Functionality
    Internal
    #>
    $ManifestPath = '.\PowerShell\ScubaGear\ScubaGear.psd1'
    $VersionRegex = "\'\d+\.\d+\.\d+\'"
    $PreviousVersion = ''
    (Get-Content -Path $ManifestPath) | ForEach-Object {
        $ModuleVersionRegex = $_ -match "ModuleVersion = $($VersionRegex)"
        if ($ModuleVersionRegex) {
            $_ -match $VersionRegex | Out-Null
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PreviousVersion')]
            $PreviousVersion = $matches[0] -replace "'", ""
            $_ -replace $VersionRegex, "'${env:NEW_VERSION_NUMBER}'"
        }
        else {
            $_
        }
    } | Set-Content -Path $ManifestPath
    $PreviousVersion
}

function Set-ScubaGearVersionDoc {
    <#
    .Description
    Replace ScubaGear module version in
    ./docs/installation/github
    ./docs/installation/psgallery
    .Functionality
    Internal
    #>
    $GitHubDocPath = './docs/installation/github.md'
    $ZipRegex = "ScubaGear-v\d+\.\d+\.\d+"
    $ZipVerReplace = "ScubaGear-v${env:NEW_VERSION_NUMBER}"
    (Get-Content -Path $GitHubDocPath) | ForEach-Object {
        $ZipVerMatch = $_ -match $ZipRegex
        if ($ZipVerMatch) {
            $_ -replace $ZipRegex, $ZipVerReplace
        }
        else {
            $_
        }
    } | Set-Content -Path $GitHubDocPath

    $PSGalleryDocPath = './docs/installation/psgallery.md'
    $VersionRegex = "\d+\.\d+\.\d+"
    $VersionReplace = "${env:NEW_VERSION_NUMBER}"
    (Get-Content -Path $PSGalleryDocPath) | ForEach-Object {
        $VersionMatch = $_ -match $VersionRegex
        if ($VersionMatch) {
            $_ -replace $VersionRegex, $VersionReplace
        }
        else {
            $_
        }
    } | Set-Content -Path $PSGalleryDocPath
}

function New-PRBody {
    <#
    .Description
    Create the Pull Request Body
    From the ScubaGear PR template
    .Functionality
    Internal
    #>
    $PRTemplatePath = '.\.github\pull_request_template.md'

    $Description = '<!-- Describe the "what" of your changes in detail. -->'
    $Motivation = '<!-- Why is this change required\? -->'
    $Testing = '<!-- see how your change affects other areas of the code, etc. -->'
    $RemoveHeader = '# <!-- Use the title to describe PR changes in the imperative mood --> #'

    $NewDescription = "- This PR was create by a GitHub Action to bump ScubaGear's module version in the manifest and the README.`n" + `
        "- Please fill out the rest of the template that the Action did not cover. `n"
    $NewMotivation = "- Bump ScubaGear's module version to v${env:NEW_VERSION_NUMBER} before the next release`n"
    $NewTesting = "- A human should still check if the version bumping was successful by running ScubaGear.`n"

    $PRTemplateContent = (Get-Content -Path $PRTemplatePath) | ForEach-Object {
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
    $PRTemplateContent
}

function Test-ScubaGearVersionWorkflowInput {
    <#
    .Description
    This function does input validation for the module version bump workflow
    .Functionality
    Internal
    #>

    # Check if input is valid SemVer
    # fail workflow if input is not
    $SemVerPattern = '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){2}(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
    $ValidVersion = $false
    if ($env:NEW_VERSION_NUMBER -match $semverPattern) {
        $ValidVersion = $true
    }

    # Separate from above conditional for easier debugging
    if (-not $ValidVersion) {
        Write-Output "Invalid Semantic Version: $($env:NEW_VERSION_NUMBER) does not conform to SemVer standards."
        exit 1
    }
    Write-Output "Past Version Validation"

    #
    # delete the branch if it already exists
    #
    $ScubaGearVersionBumpBranch = "scubagear-version-bump-${env:NEW_VERSION_NUMBER}"

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Temp')]
    $Temp = git ls-remote --exit-code --heads origin $ScubaGearVersionBumpBranch

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '$VersionBranchExists')]
    $VersionBranchExists = $false
    if ($LASTEXITCODE -eq 0) {
        $VersionBranchExists = $true
    }
    if ($VersionBranchExists) {
        git push origin --delete $ScubaGearVersionBumpBranch
        Write-Output "Branch '$ScubaGearVersionBumpBranch' deleted."
    }
    Write-Output "Past Branch Existance Check"

    #
    # Check if version bump label exists
    # Create one if it does not
    $LabelName = "version bump"
    $Repo = "$env:REPO" # This environment variable was set from the workflow yaml file

    # Check if the label exists otherwise create it
    $Labels = gh api repos/$REPO/labels | ConvertFrom-Json
    $LabelExists = $Labels | Where-Object { $_.name -eq $LabelName }

    if (-not $LabelExists) {
        $LabelColor = "d4c5f9"
        # Create the label
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '$SuppressMessage')]
        $SuppressMessage = gh api repos/$Repo/labels -X POST -f name="$($LabelName)" -f color="$($LabelColor)"
        Write-Output "Label '$LabelName' did not exist, so it was created."
    }
    Write-Output "Past Label Existance Check"

    if ($ValidVersion) {
        # Note that git-ls will always fail with exit code 1 when the branch does not exist.
        # Setting exit 0 (success) at the end of this workflow to prevent that error
        Write-Output "Input validation successful moving to next step"
        exit 0
    }
}

function Set-ScubaGearModuleVersion {
    <#
    .Description
    This main function to bump ScubaGear's module version
    .Functionality
    Internal
    #>

    # Replace the module version in the manifest
    $PreviousVersion = Set-ScubaGearVersionManifest

    # Replace the module version in the documentation
    Set-ScubaGearVersionDoc

    # Create the GitHub Pull Request
    $PRTemplateContent = New-PRBody

    # Create the PR
    # TODO abstract this out into a reusable function in the future.
    $ScubaGearVersionBumpBranch = "scubagear-version-bump-${env:NEW_VERSION_NUMBER}"
    git config --global user.email "action@github.com"
    git config --global user.name "GitHub Action"
    git checkout -b $ScubaGearVersionBumpBranch
    git add .
    git commit -m "Update ScubaGear version to ${env:NEW_VERSION_NUMBER}"
    git push origin $ScubaGearVersionBumpBranch
    gh pr create `
        -B main `
        -H $ScubaGearVersionBumpBranch `
        --title "Bump ScubaGear module version from v$($PreviousVersion) to v${env:NEW_VERSION_NUMBER}" `
        --body "${PRTemplateContent}" `
        --label "version bump"
}

Export-ModuleMember -Function @(
    'Set-ScubaGearModuleVersion',
    'Test-ScubaGearVersionWorkflowInput'
)