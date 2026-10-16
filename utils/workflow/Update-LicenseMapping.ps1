<#
.SYNOPSIS
    Helpers used by the monthly license mapping update workflow and the
    release build gate that verifies the mapping is current.
.DESCRIPTION
    Downloads Microsoft's Product names and service plan identifiers CSV,
    normalizes it to ScubaGear's three-column mapping format, and either
    overwrites the checked-in file or fails if the checked-in file is stale.
#>

$script:LicenseMappingRelativePath = 'PowerShell/ScubaGear/Modules/CreateReport/MicrosoftLicenseToProductNameMappings.csv'
$script:MicrosoftLicenseCsvUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'

function Get-LicenseMappingPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )

    return (Join-Path -Path $RepoPath -ChildPath $script:LicenseMappingRelativePath)
}

function Get-NormalizedLicenseMappingRows {
    <#
    .SYNOPSIS
        Normalize Microsoft's licensing CSV into ScubaGear's product mapping rows.
    .PARAMETER CsvPath
        Path to a downloaded Microsoft licensing CSV (6 columns).
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $CsvPath
    )

    if (-not (Test-Path -PathType Leaf -Path $CsvPath)) {
        throw "Fatal Error: Couldn't find licensing CSV at path $CsvPath"
    }

    # Microsoft's CSV is one row per service plan; collapse it down to ScubaGear's
    # three columns (Product_Display_Name, String_Id, GUID), trim stray whitespace,
    # lowercase GUIDs for consistent comparisons, and drop duplicate rows.
    $Rows = Import-Csv -Path $CsvPath | ForEach-Object {
        [pscustomobject]@{
            Product_Display_Name = $_.Product_Display_Name.Trim()
            String_Id            = $_.String_Id.Trim()
            GUID                 = $_.GUID.Trim().ToLowerInvariant()
        }
    } | Sort-Object Product_Display_Name, String_Id, GUID -Unique

    if (-not $Rows -or @($Rows).Count -eq 0) {
        throw "Fatal Error: Normalized licensing CSV contained no rows"
    }

    return @($Rows)
}

function Get-LicenseMappingKeySet {
    <#
    .SYNOPSIS
        Build a comparable set of Product|String_Id|GUID keys from mapping rows.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [object[]]
        $Rows
    )

    return [System.Collections.Generic.HashSet[string]]@(
        $Rows | ForEach-Object {
            '{0}|{1}|{2}' -f $_.Product_Display_Name, $_.String_Id, $_.GUID.ToLowerInvariant()
        }
    )
}

function Get-LatestNormalizedLicenseMappingRows {
    <#
    .SYNOPSIS
        Download Microsoft's licensing CSV and return normalized product mapping rows.
    #>
    $TempRoot = if (-not [string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    $DownloadPath = Join-Path -Path $TempRoot -ChildPath ("ms-license-mapping-{0}.csv" -f [guid]::NewGuid())

    try {
        Write-Warning "Downloading Microsoft licensing CSV..."
        Invoke-WebRequest -Uri $script:MicrosoftLicenseCsvUrl -OutFile $DownloadPath -UseBasicParsing
        return (Get-NormalizedLicenseMappingRows -CsvPath $DownloadPath)
    }
    finally {
        if (Test-Path -Path $DownloadPath) {
            Remove-Item -Path $DownloadPath -Force -ErrorAction SilentlyContinue
        }
    }
}

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

    $DestinationPath = Get-LicenseMappingPath -RepoPath $RepoPath
    if (-not (Test-Path -PathType Leaf -Path $DestinationPath)) {
        throw "Fatal Error: Couldn't find license mapping CSV at path $DestinationPath"
    }

    $Rows = Get-LatestNormalizedLicenseMappingRows
    $Rows | Export-Csv -Path $DestinationPath -NoTypeInformation -Encoding UTF8

    Write-Warning "Wrote $($Rows.Count) product mappings to $DestinationPath"
    return $Rows.Count
}

function Test-LicenseMappingIsCurrent {
    <#
    .SYNOPSIS
        Fail if the checked-in license mapping CSV is behind Microsoft's published CSV.
    .DESCRIPTION
        Intended as a pre-release gate. Downloads and normalizes Microsoft's CSV,
        compares product triples to the checked-in file, and throws if they differ.
    .PARAMETER RepoPath
        Path to the repo.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RepoPath
    )

    $ExistingMappingPath = Get-LicenseMappingPath -RepoPath $RepoPath
    if (-not (Test-Path -PathType Leaf -Path $ExistingMappingPath)) {
        throw "Fatal Error: Couldn't find license mapping CSV at path $ExistingMappingPath"
    }

    $LatestRows = Get-LatestNormalizedLicenseMappingRows
    $CurrentRows = Import-Csv -Path $ExistingMappingPath | ForEach-Object {
        [pscustomobject]@{
            Product_Display_Name = $_.Product_Display_Name.Trim()
            String_Id            = $_.String_Id.Trim()
            GUID                 = $_.GUID.Trim().ToLowerInvariant()
        }
    }

    $LatestKeys = Get-LicenseMappingKeySet -Rows $LatestRows
    $CurrentKeys = Get-LicenseMappingKeySet -Rows $CurrentRows

    $OnlyInLatest = $LatestKeys | Where-Object { -not $CurrentKeys.Contains($_) }
    $OnlyInCurrent = $CurrentKeys | Where-Object { -not $LatestKeys.Contains($_) }

    if ((@($OnlyInLatest).Count -eq 0) -and (@($OnlyInCurrent).Count -eq 0)) {
        Write-Output "License mapping is up to date ($($CurrentKeys.Count) product mappings)."
        return
    }

    $Message = @(
        "License mapping is out of date and must be refreshed before release."
        "Checked-in mappings: $($CurrentKeys.Count); Microsoft latest: $($LatestKeys.Count)."
        "Entries only in Microsoft latest: $(@($OnlyInLatest).Count)."
        "Entries only in checked-in file: $(@($OnlyInCurrent).Count)."
        "Run the 'Update license mapping if necessary' workflow (or utils/workflow/Update-LicenseMapping.ps1),"
        "merge the resulting PR, then re-run this release workflow."
    ) -join ' '

    if (@($OnlyInLatest).Count -gt 0) {
        Write-Warning ("Sample new mappings (up to 10):`n  " + (($OnlyInLatest | Select-Object -First 10) -join "`n  "))
    }
    if (@($OnlyInCurrent).Count -gt 0) {
        Write-Warning ("Sample removed mappings (up to 10):`n  " + (($OnlyInCurrent | Select-Object -First 10) -join "`n  "))
    }

    throw $Message
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

    $MappingPath = Get-LicenseMappingPath -RepoPath $RepoPath
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
