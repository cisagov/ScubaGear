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
        Write-Information "Found OPA at: $opaExe" -InformationAction Continue
        break
    }
}

if (-not $opaExe) {
    # Try to find it via Get-Command
    $opaCmd = Get-Command opa -ErrorAction SilentlyContinue
    if ($opaCmd) {
        $opaExe = $opaCmd.Source
        Write-Information "Found OPA at: $opaExe" -InformationAction Continue
    }
}

if (-not $opaExe) {
    Write-Error "ERROR: OPA executable not found!"
    Write-Warning "Please ensure OPA is installed and in your PATH"
    Write-Warning "You can download OPA from: https://www.openpolicyagent.org/docs/latest/#running-opa"
    exit 1
}

# Navigate to ScubaGear directory
$scubaGearPath = "C:\Users\skirkpatrick\OneDrive - Microsoft\Documents\GitHub\ScubaGear1664\PowerShell\ScubaGear"
Push-Location $scubaGearPath

Write-Information "`nRunning OPA tests for Teams..." -InformationAction Continue

# Run the tests
& $opaExe test Testing/Unit/Rego/Teams --verbose

$exitCode = $LASTEXITCODE

Pop-Location

if ($exitCode -eq 0) {
    Write-Information "`nAll tests PASSED!" -InformationAction Continue
} else {
    Write-Error "`nSome tests FAILED!"
}

exit $exitCode
