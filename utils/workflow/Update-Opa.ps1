function Determine-OpaUpdateRequirements {
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
    $LatestOPAVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/open-policy-agent/opa/releases/latest" | Select-Object -ExpandProperty tag_name
    $LatestOPAVersion = $LatestOPAVersion -replace "v", ""

    # Check if there is already an update branch
    $OPAVersionBumpBranch = "opa-version-bump-$($LatestOPAVersion)"
    $Temp = git ls-remote --exit-code --heads origin $OPAVersionBumpBranch
    $OPAVersionBranchExists = $false
    if ($LASTEXITCODE -eq 0) {
        $OPAVersionBranchExists = $true
    }

    # Check if our current OPA version is outdated
    # $OPAVersionPath = '.\PowerShell\ScubaGear\Modules\Support\Support.psm1'
    $OPAVersionPath = Join-Path -Path $RepoPath PowerShell/ScubaGear/Modules/Support/Support.psm1
    $OPAVerRegex = "\'\d+\.\d+\.\d+\'"
    $ExpectedVersionPattern = "ExpectedVersion = $OPAVerRegex"
    $SupportModule = Get-Content $OPAVersionPath -Raw

    # Find our current OPA version using some dirty string
    # manipulation
    # $ScubaConfigPath = '.\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'
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
        Write-Output "OPA version update required."
    }
    else {
        Write-Output "OPA version update is not required. Update branch already exists or OPA version is already up to date."
    }
    # Write-Warning "Current ScubaGear default OPA Version: v$($CurrentOPAVersion) Latest OPA version: v$($LatestOPAVersion)"

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

}