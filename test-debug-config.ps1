# Import the ScubaConfigValidator module
using module 'c:\ActiveDevelopment\Github\cisagov\ScubaGear-1437-validate-scubaconfig\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfigValidator.psm1'

# Test script to demonstrate debugMode controlled by configuration defaults
Write-Host "=== Testing Debug Mode Control via Configuration ===" -ForegroundColor Cyan

# Initialize the validator
$modulePath = "c:\ActiveDevelopment\Github\cisagov\ScubaGear-1437-validate-scubaconfig\PowerShell\ScubaGear\Modules\ScubaConfig"
[ScubaConfigValidator]::Initialize($modulePath)
Write-Host "Validator initialized" -ForegroundColor Green

# Create a simple test configuration file
$testConfigContent = @"
ProductNames: 
  - aad
Organization: contoso.com
OrgName: Contoso Corporation
M365Environment: commercial
"@

$testConfigPath = "c:\temp\test-scuba-config.yaml"
$testDir = Split-Path $testConfigPath -Parent
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force
}
$testConfigContent | Out-File -FilePath $testConfigPath -Encoding UTF8

# Show current debugMode setting
$defaults = [ScubaConfigValidator]::GetDefaults()
$currentDebugMode = $defaults.outputSettings.debugMode
Write-Host "`nCurrent debugMode setting in configuration: $currentDebugMode" -ForegroundColor Yellow

# Test with default debug mode (controlled by configuration)
Write-Host "`n1. Testing with default debug mode (from configuration):" -ForegroundColor White
$DebugPreference = "Continue"  # Make debug output visible
try {
    Write-Host "   Calling ValidateYamlFile with no debug parameter..." -ForegroundColor Gray
    $result1 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath)
    Write-Host "   Validation completed. Errors: $($result1.ValidationErrors.Count)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test with explicit debug mode = true
Write-Host "`n2. Testing with explicit debug mode = true:" -ForegroundColor White
try {
    Write-Host "   Calling ValidateYamlFile with debug = true..." -ForegroundColor Gray
    $result2 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $true)
    Write-Host "   Validation completed. Errors: $($result2.ValidationErrors.Count)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test with explicit debug mode = false
Write-Host "`n3. Testing with explicit debug mode = false:" -ForegroundColor White
try {
    Write-Host "   Calling ValidateYamlFile with debug = false..." -ForegroundColor Gray
    $result3 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $false)
    Write-Host "   Validation completed. Errors: $($result3.ValidationErrors.Count)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

$DebugPreference = "SilentlyContinue"  # Restore default

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "• The debugMode can be controlled via the 'outputSettings.debugMode' property" -ForegroundColor White
Write-Host "• When ValidateYamlFile() is called without a debug parameter, it uses the config default" -ForegroundColor White
Write-Host "• When ValidateYamlFile(path, debugMode) is called, it uses the explicit parameter" -ForegroundColor White
Write-Host "• To see debug output, set `$DebugPreference = 'Continue' before calling validation" -ForegroundColor White

# Show how to modify the debugMode setting programmatically
Write-Host "`n=== Modifying debugMode Setting ===" -ForegroundColor Cyan
Write-Host "To change the default debugMode setting in ScubaConfigDefaults.json:" -ForegroundColor White
Write-Host "  Change 'debugMode': false to 'debugMode': true in the outputSettings section" -ForegroundColor Gray

# Clean up
if (Test-Path $testConfigPath) {
    Remove-Item $testConfigPath -Force
    Write-Host "`nCleaned up test file: $testConfigPath" -ForegroundColor Green
}