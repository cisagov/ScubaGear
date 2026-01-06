# Test script to run OPA tests for Teams
# This script finds the OPA executable and runs the tests

# Try to find OPA in common locations
$opaPaths = @(
    "opa.exe",
    ".\opa.exe",
    "C:\Program Files\opa\opa.exe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\opa.exe",
    "$env:ProgramFiles\opa\opa.exe"
)

$opaExe = $null
foreach ($path in $opaPaths) {
    if (Test-Path $path) {
        $opaExe = $path
        Write-Host "Found OPA at: $opaExe" -ForegroundColor Green
        break
    }
}

if (-not $opaExe) {
    # Try to find it via Get-Command
    $opaCmd = Get-Command opa -ErrorAction SilentlyContinue
    if ($opaCmd) {
        $opaExe = $opaCmd.Source
        Write-Host "Found OPA at: $opaExe" -ForegroundColor Green
    }
}

if (-not $opaExe) {
    Write-Host "ERROR: OPA executable not found!" -ForegroundColor Red
    Write-Host "Please ensure OPA is installed and in your PATH" -ForegroundColor Yellow
    Write-Host "You can download OPA from: https://www.openpolicyagent.org/docs/latest/#running-opa" -ForegroundColor Yellow
    exit 1
}

# Navigate to ScubaGear directory
$scubaGearPath = "C:\Users\skirkpatrick\OneDrive - Microsoft\Documents\GitHub\ScubaGear1664\PowerShell\ScubaGear"
Push-Location $scubaGearPath

Write-Host "`nRunning OPA tests for Teams..." -ForegroundColor Cyan

# Run the tests
& $opaExe test Testing/Unit/Rego/Teams --verbose

$exitCode = $LASTEXITCODE

Pop-Location

if ($exitCode -eq 0) {
    Write-Host "`nAll tests PASSED!" -ForegroundColor Green
} else {
    Write-Host "`nSome tests FAILED!" -ForegroundColor Red
}

exit $exitCode
