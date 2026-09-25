<#
.SYNOPSIS
    Helpers used by the monthly license mapping update workflow.
.DESCRIPTION
    Downloads Microsoft's Product names and service plan identifiers CSV,
    normalizes it to ScubaGear's three-column mapping format, and writes it
    directly over the checked-in file. The calling workflow uses `git diff`
    to decide whether anything actually changed and a PR is needed.
#>

$script:LicenseMappingRelativePath = 'PowerShell/ScubaGear/Modules/CreateReport/MicrosoftLicenseToProductNameMappings.csv'
$script:MicrosoftLicenseCsvUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'

function Update-LicenseMappingFile {
    <#
    .SYNOPSIS
        Download Microsoft's licensing CSV, normalize it, and overwrite the
        checked-in ScubaGear mapping file in place.
    .PARAMETER RepoPath
        Path to the repo.
    .OUTPUTS
        The number of unique product mappings written.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )

    $DestinationPath = Join-Path -Path $RepoPath -ChildPath $script:LicenseMappingRelativePath
    if (-not (Test-Path -PathType Leaf -Path $DestinationPath)) {
        throw "Fatal Error: Couldn't find license mapping CSV at path $DestinationPath"
    }

    $TempRoot = if (-not [string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    $DownloadPath = Join-Path -Path $TempRoot -ChildPath ("ms-license-mapping-{0}.csv" -f [guid]::NewGuid())

    try {
        Write-Warning "Downloading Microsoft licensing CSV..."
        Invoke-WebRequest -Uri $script:MicrosoftLicenseCsvUrl -OutFile $DownloadPath -UseBasicParsing

        # Microsoft's CSV is one row per service plan; collapse it down to ScubaGear's
        # three columns (Product_Display_Name, String_Id, GUID), trim stray whitespace,
        # lowercase GUIDs for consistent comparisons, and drop duplicate rows.
        $Rows = Import-Csv -Path $DownloadPath | ForEach-Object {
            [pscustomobject]@{
                Product_Display_Name = $_.Product_Display_Name.Trim()
                String_Id             = $_.String_Id.Trim()
                GUID                  = $_.GUID.Trim().ToLowerInvariant()
            }
        } | Sort-Object Product_Display_Name, String_Id, GUID -Unique

        if (-not $Rows -or $Rows.Count -eq 0) {
            throw "Fatal Error: Normalized licensing CSV contained no rows"
        }

        # -NoTypeInformation drops the '#TYPE' header line; BOM matches the file's existing encoding.
        $Rows | Export-Csv -Path $DestinationPath -NoTypeInformation -Encoding UTF8

        Write-Warning "Wrote $($Rows.Count) product mappings to $DestinationPath"
        return $Rows.Count
    }
    finally {
        if (Test-Path -Path $DownloadPath) {
            Remove-Item -Path $DownloadPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-LicenseMappingUpdatePr {
    <#
    .SYNOPSIS
        Commit the already-updated mapping CSV on a new branch and open a pull request.
    .PARAMETER RepoPath
        Path to the repo.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )

    $MappingPath = Join-Path -Path $RepoPath -ChildPath $script:LicenseMappingRelativePath
    $BranchName = "license-mapping-update-$(Get-Date -Format 'yyyyMMdd')"

    git config --global user.email 'action@github.com'
    git config --global user.name 'GitHub Action'
    git checkout -b $BranchName
    git add -- "$MappingPath"
    git commit -m 'Update Microsoft license product name mappings'
    git push origin $BranchName

    gh pr create -B main -H $BranchName `
        --title 'Update Microsoft license product name mappings' `
        --body-file (Join-Path -Path $RepoPath -ChildPath '.github/pull_request_template.md') `
        --label 'enhancement'

    return $BranchName
}

function Approve-LicenseMappingUpdatePr {
    <#
    .SYNOPSIS
        Auto-approve and enable auto-merge for the license mapping update PR.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $LicenseMappingBumpBranch
    )

    $PrNumber = gh pr list --head $LicenseMappingBumpBranch --json number --jq '.[0].number'
    if ([string]::IsNullOrWhiteSpace($PrNumber)) {
        throw "Fatal Error: Could not find a pull request for branch $LicenseMappingBumpBranch"
    }

    Write-Warning "Auto-approving pull request #$PrNumber"
    gh pr review $PrNumber --approve --body 'Automated approval for monthly Microsoft license mapping update.'
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Pull request approval was skipped or failed (common when GITHUB_TOKEN cannot approve its own PR)."
        $global:LASTEXITCODE = 0
    }

    Write-Warning "Enabling auto-merge for pull request #$PrNumber"
    gh pr merge $PrNumber --auto --squash
}
