<#
.SYNOPSIS
    Local debug script to verify Get-DlpPolicy / Remove-DlpPolicy work correctly
    before running the full Pester suite.
.EXAMPLE
    .\Testing\Functional\Products\Debug-DlpPolicy.ps1 -TenantDomain "contoso.onmicrosoft.us" -M365Environment "gcchigh"
#>
param(
    [Parameter(Mandatory = $true)][string]$TenantDomain,
    [string]$M365Environment = "gcchigh"
)

$ScubaModule = Join-Path $PSScriptRoot "../../../PowerShell/ScubaGear/ScubaGear.psd1"
Import-Module (Resolve-Path $ScubaModule) -Force

$PPHelperPath = Join-Path $PSScriptRoot "../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/PowerPlatformRestHelper.psm1"
Import-Module (Resolve-Path $PPHelperPath) -Force

Write-Host "`n--- Authenticating interactively ---" -ForegroundColor Cyan
$script:PPBaseUrl    = Get-PowerPlatformBaseUrl -M365Environment $M365Environment
$script:PPAccessToken = Get-PowerPlatformAccessTokenInteractive -Tenant $TenantDomain -M365Environment $M365Environment

# Dot-source test utilities (defines Get-DlpPolicy, Remove-DlpPolicy, etc.)
. (Join-Path $PSScriptRoot "FunctionalTestUtils.ps1")

Write-Host "`n--- Current DLP policies ---" -ForegroundColor Cyan
$Before = Get-DlpPolicy
if ($Before.value.Count -eq 0) {
    Write-Host "  (none)" -ForegroundColor Yellow
} else {
    $Before.value | ForEach-Object {
        Write-Host "  name=$($_.name)" -ForegroundColor White
        Write-Host "  id  =$($_.id)" -ForegroundColor Gray
        Write-Host "  displayName=$($_.displayName)" -ForegroundColor White
        Write-Host ""
    }
}

$Target = $Before.value | Where-Object { $_.displayName -eq "DLP functional test" }
if (-not $Target) {
    Write-Host "`n'DLP functional test' policy not found — creating one for testing..." -ForegroundColor Yellow
    New-AdminDlpPolicy -DisplayName "DLP functional test"
    $Target = (Get-DlpPolicy).value | Where-Object { $_.displayName -eq "DLP functional test" }
    Write-Host "Created. id=$($Target.id)" -ForegroundColor Green
}

Write-Host "`n--- Attempting to delete 'DLP functional test' via id ---" -ForegroundColor Cyan
Write-Host "  PolicyName (id) = $($Target.id)" -ForegroundColor Gray
try {
    $Target | Select-Object @{ Name="PolicyName"; Expression={$_.id} } | Remove-DlpPolicy
    Write-Host "  DELETE call completed without exception." -ForegroundColor Green
} catch {
    Write-Host "  DELETE FAILED: $_" -ForegroundColor Red
}

Write-Host "`n--- DLP policies after delete ---" -ForegroundColor Cyan
$After = Get-DlpPolicy
if ($After.value.Count -eq 0) {
    Write-Host "  (none) - DELETE WORKED" -ForegroundColor Green
} else {
    $After.value | ForEach-Object {
        $Color = if ($_.displayName -eq "DLP functional test") { "Red" } else { "White" }
        Write-Host "  - $($_.displayName) [$($_.id)]" -ForegroundColor $Color
    }
    if ($After.value | Where-Object { $_.displayName -eq "DLP functional test" }) {
        Write-Host "`n  'DLP functional test' STILL EXISTS after delete!" -ForegroundColor Red
    }
}
