function Set-ScubaGearVersionManifest {
    #
    # Replace ScubaGear module version in the ScubaGear.psd1 manifest.
    #
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
    #
    # Replace ScubaGear module version in
    # ./docs/installation/github
    # ./docs/installation/psgallery
    #
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
    #
    # Create the Pull Request body
    #
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
function Set-ScubaGearModuleVersion {
    <#
    This function
    #>

    $PreviousVersion = Set-ScubaGearVersionManifest
    Set-ScubaGearVersionDoc
    $PRTemplateContent = New-PRBody

    # Create the PR
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
    'Set-ScubaGearModuleVersion'
)