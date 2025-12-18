# Test script to verify debug mode is now properly used from configuration
using module 'c:\ActiveDevelopment\Github\cisagov\ScubaGear-1437-validate-scubaconfig\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

Write-Host "=== Testing Debug Mode Configuration in LoadConfig ===" -ForegroundColor Cyan

# Create a simple test configuration file with issues to trigger debug output
$testConfigContent = @"
ProductNames: 
  - aad
  - invalidproduct
Organization: contoso.com
OrgName: Contoso Corporation
M365Environment: commercial
OPAPath: /this/path/does/not/exist/anywhere
"@

$testConfigPath = "c:\temp\test-scuba-debug.yaml"
$testDir = Split-Path $testConfigPath -Parent
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force
}
$testConfigContent | Out-File -FilePath $testConfigPath -Encoding UTF8

Write-Host "Created test configuration file at: $testConfigPath" -ForegroundColor Green

# Set debug preference to see output
$DebugPreference = "Continue"

Write-Host "`nTesting LoadConfig with debugMode from configuration..." -ForegroundColor Yellow

try {
    $Config = [ScubaConfig]::GetInstance()
    $Success = $Config.LoadConfig([System.IO.FileInfo]$testConfigPath)
    Write-Host "LoadConfig completed successfully: $Success" -ForegroundColor Green
} catch {
    Write-Host "LoadConfig failed: $($_.Exception.Message)" -ForegroundColor Red
}

$DebugPreference = "SilentlyContinue"  # Restore default

# Clean up
if (Test-Path $testConfigPath) {
    Remove-Item $testConfigPath -Force
    Write-Host "`nCleaned up test file: $testConfigPath" -ForegroundColor Green
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "If debugMode is true in the configuration, you should see detailed debug output above." -ForegroundColor White