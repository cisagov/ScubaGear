using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

function Set-OPAVersionDoc {
    <#
    .Description
    Replace OPA version in
    ./docs/prerequisites/dependencies.md
    .Functionality
    Internal
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $LatestOpaVersion
    )
    $GitHubDocPath = './docs/prerequisites/dependencies.md'
    $VerRegex = "v\d+\.\d+\.\d+"
    $VerReplace = "v$($LatestOpaVersion)"
    (Get-Content -Path $GitHubDocPath) | ForEach-Object {
        $VerMatch = $_ -match $VerRegex
        if ($VerMatch) {
            $_ -replace $VerRegex, $VerReplace
        }
        else {
            $_
        }
    } | Set-Content -Path $GitHubDocPath
}

function Confirm-OpaUpdateRequirements {
    <#
        .SYNOPSIS
            Determine if OPA update is required
    #>

    Write-Warning "Determining if OPA needs to be updated..."

    # Assume it does not need to be update until proven otherwise
    $UpdateRequired = $false
    # Get latest version of OPA via REST
    $LatestOPAVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/open-policy-agent/opa/releases/latest" | Select-Object -ExpandProperty tag_name
    $LatestOPAVersion = $LatestOPAVersion -replace "v", ""

    # Check if there is already an update branch
    $OPAVersionBumpBranch = "opa-version-bump-$($LatestOPAVersion)"
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = '$Temp required to avoid having PS eat the return code from git.')]
    $Temp = git ls-remote --exit-code --heads origin $OPAVersionBumpBranch
    $OPAVersionBranchExists = $false
    if ($LASTEXITCODE -eq 0) {
        $OPAVersionBranchExists = $true
    }

    # Get the version of OPA defined in the config class.
    $CurrentOPAVersion = [ScubaConfig]::GetOpaVersion()

    # Check to see if updates are required, and if not, why not.
    $Summary = ''
    if ([System.Version]::Parse($LatestOPAVersion) -gt [System.Version]::Parse($CurrentOPAVersion)) {
        if (-not $OPAVersionBranchExists) {
            $Summary = "OPA version update required."
            $UpdateRequired = $true
        }
        else {
            $Summary = "Update branch ($($OPAVersionBumpBranch)) already exists; no update required."
        }
    }
    else {
        $Summary = "OPA version is already up to date; no update required."
    }

    # Return values in a hashtable
    $ReturnValues = @{
        "Summary"              = $Summary
        "LatestOPAVersion"     = $LatestOPAVersion
        "OPAVersionBumpBranch" = $OPAVersionBumpBranch
        "UpdateRequired"       = $UpdateRequired
        "CurrentOPAVersion"    = $CurrentOPAVersion
    }
    return $ReturnValues
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

    Write-Warning "Updating OPA versions and compatible OPA versions in ScubaConfigDefaults.json..."

    $ScubaConfigDefaultsPath = Join-Path -Path $RepoPath -ChildPath 'PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfigDefaults.json'

    if (-not (Test-Path -PathType Leaf -Path $ScubaConfigDefaultsPath)) {
        throw "Fatal Error: Couldn't find ScubaConfigDefaults.json at path $ScubaConfigDefaultsPath"
    }

    $Raw = Get-Content -Path $ScubaConfigDefaultsPath -Raw
    $ConfigDefaults = $Raw | ConvertFrom-Json

    if ($null -eq $ConfigDefaults.defaults.OPAVersion) {
        throw "Fatal Error: Couldn't find defaults.OPAVersion in ScubaConfigDefaults.json"
    }

    if ($null -eq $ConfigDefaults.metadata.compatibleOpaVersions) {
        throw "Fatal Error: Couldn't find metadata.compatibleOpaVersions in ScubaConfigDefaults.json"
    }

    $PreviousDefault = $CurrentOpaVersion
    $NewDefault = $LatestOpaVersion

    # Move the previous default to the end of compatibleOpaVersions
    $Versions = @($ConfigDefaults.metadata.compatibleOpaVersions) | Where-Object { $_ -ne $PreviousDefault }
    $Versions += $PreviousDefault

    # Creates the expected format for ScubaConfigDefaults.json, e.g. ["1.1.0","1.2.0",...]
    $CompatibleOpaVersions = ($Versions | ConvertTo-Json -Compress)

    $Raw = $Raw -replace '"compatibleOpaVersions"\s*:\s*\[[^\]]*\]', ('"compatibleOpaVersions": ' + $CompatibleOpaVersions)
    $Raw = $Raw -replace '"OPAVersion"\s*:\s*"[^"]*"', ('"OPAVersion": "' + $NewDefault + '"')

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ScubaConfigDefaultsPath, $Raw, $utf8NoBom)
    Write-Warning "Set defaults.OPAVersion to $NewDefault."
    Write-Warning "Added previous default ($PreviousDefault) to metadata.compatibleOpaVersions."
}

function Invoke-UnitTestsWithNewOPAVersion {
    <#
    .SYNOPSIS
    Run ScubaGear OPA unit tests with the latest version of an OPA executable
    .PARAMETER LatestOpaVersion
    The new version in ScubaConfig used to update
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $LatestOpaVersion
    )

    # Download the latest OPA version from the OPA website
    $OPAExe = "opa_windows_amd64.exe"
    $InstallUrl = "https://openpolicyagent.org/downloads/v$($LatestOpaVersion)/$OPAExe"
    $OutFile = "./$($OPAExe)"
    try {
        Write-Information "Downloading $InstallUrl"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
        Write-Information ""
        Write-Information "`nDownload of `"$OutFile`" finished."
    }
    catch {
        Write-Error "Unable to download OPA executable. To try manually downloading, see details found under the section titled 'OPA Installation' within the 'Dependencies' markdown linked in the README"
    }
    finally {
        $WebClient.Dispose()
    }

    # Run the unit test with the latest OPA version download
    .\Testing\RunUnitTests.ps1 -OPAPath "./"
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
            The branch in the repo that will update the version of OPA
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

    $UnitTestResults = Invoke-UnitTestsWithNewOPAVersion -LatestOpaVersion $LatestOpaVersion

    # Update the docs with the latest tested OPA version
    Set-OPAVersionDoc -LatestOpaVersion $LatestOpaVersion

    # Create the PR body
    $PRTemplatePath = Join-Path -Path $RepoPath -ChildPath '.github/pull_request_template.md'
    $Description = '<!-- Describe the "what" of your changes in detail. -->'
    $Motivation = '<!-- Why is this change required\? -->'
    $Testing = '<!-- see how your change affects other areas of the code, etc. -->'
    $RemoveHeader = '# <!-- Use the title to describe PR changes in the imperative mood --> #'
    $NewDescription = "- This pull request was created by a GitHub Action to bump ScubaGear's Open Policy Agent (OPA) executable version dependency.`n - Please fill out the rest of the template that the Action did not cover. `n"
    $NewMotivation = "- Bump to the latest OPA version v$($LatestOpaVersion) `n"
    $NewTesting = "- Rego Unit Test results for OPA v$($LatestOpaVersion): `n $($UnitTestResults) `n - A smoke test is also being run against this branch. Check the [latest smoke test](https://github.com/cisagov/ScubaGear/actions/workflows/run_smoke_test.yaml) targeting branch: $($OpaVersionBumpBranch)"

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
    # Remove UTF-8 content from the template that comes from the emoji,
    # because it is not being rendered correctly.
    $PrTemplateContent = $PrTemplateContent -replace '[^\x00-\x7F]', ''

    git config --global user.email "action@github.com"
    git config --global user.name "GitHub Action"
    git checkout -b "$($OpaVersionBumpBranch)"
    git add .
    git commit -m "Bump OPA version from v$($CurrentOpaVersion) to  v$($LatestOpaVersion)"
    git push origin $OpaVersionBumpBranch
    gh pr create -B main -H $OpaVersionBumpBranch --title "Bump OPA version from v$($CurrentOpaVersion) to v$($LatestOpaVersion)" --body "${PrTemplateContent}" --label "version bump"
}
