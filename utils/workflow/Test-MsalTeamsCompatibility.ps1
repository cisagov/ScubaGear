#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [string]$TeamsVersion = '7.9.0'
)

$moduleCache = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-teams-$([guid]::NewGuid().ToString('N'))"
$connectHelpers = Join-Path $RepoRoot 'PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1'

try {
    Save-Module -Name MicrosoftTeams -RequiredVersion $TeamsVersion -Path $moduleCache -Force -ErrorAction Stop
    $testCases = @(
        @"
Import-Module '$connectHelpers' -Force
Initialize-Msal
Import-Module MicrosoftTeams -RequiredVersion '$TeamsVersion' -Force
"@,
        @"
Import-Module MicrosoftTeams -RequiredVersion '$TeamsVersion' -Force
Import-Module '$connectHelpers' -Force
Initialize-Msal
"@
    )

    $originalModulePath = $env:PSModulePath
    $env:PSModulePath = "$moduleCache;$originalModulePath"
    foreach ($testCase in $testCases) {
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(@"
`$ErrorActionPreference = 'Stop'
$testCase
`$versions = @([AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { `$_.GetName().Name -eq 'Microsoft.Identity.Client' } |
    ForEach-Object { `$_.GetName().Version.ToString() } |
    Select-Object -Unique)
if (`$versions.Count -ne 1) { throw "Expected one loaded MSAL version; found: `$(`$versions -join ', ')" }
Write-Output "Loaded Microsoft.Identity.Client `$(`$versions[0])"
"@))
        & powershell.exe -NoProfile -NonInteractive -EncodedCommand $encodedCommand
        if ($LASTEXITCODE -ne 0) {
            throw "MSAL/MicrosoftTeams load-order test failed with exit code $LASTEXITCODE."
        }
    }
}
finally {
    $env:PSModulePath = $originalModulePath
    Remove-Item -Path $moduleCache -Recurse -Force -ErrorAction SilentlyContinue
}
