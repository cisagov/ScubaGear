# Import the ScubaConfig modules first (using must be at the top)
using module 'c:\ActiveDevelopment\Github\cisagov\ScubaGear-1437-validate-scubaconfig\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfigValidator.psm1'

# Test script to demonstrate debug functionality with Write-Debug
# This script shows how to test the debug output from ScubaConfigValidator

# First, let's create a simple test configuration file
$testConfigContent = @"
ProductNames: 
  - aad
  - exo
Organization: contoso.com
OrgName: Contoso Corporation
OrgUnitName: IT Department
M365Environment: commercial
"@

# Create a temporary test config file
$testConfigPath = "c:\temp\test-scuba-config.yaml"
$testDir = Split-Path $testConfigPath -Parent
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force
}
$testConfigContent | Out-File -FilePath $testConfigPath -Encoding UTF8

Write-Host "Created test configuration file at: $testConfigPath" -ForegroundColor Green
Write-Host "Successfully imported ScubaConfigValidator module" -ForegroundColor Green

# Initialize the validator
$modulePath = "c:\ActiveDevelopment\Github\cisagov\ScubaGear-1437-validate-scubaconfig\PowerShell\ScubaGear\Modules\ScubaConfig"
[ScubaConfigValidator]::Initialize($modulePath)
Write-Host "Validator initialized" -ForegroundColor Green

Write-Host "`n=== Testing Debug Functionality ===" -ForegroundColor Cyan

# Test 1: Run validation without debug mode (should see no debug output)
Write-Host "`n1. Testing WITHOUT debug mode:" -ForegroundColor Yellow
try {
    $result1 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $false)
    Write-Host "   Validation completed. Errors: $($result1.ValidationErrors.Count), Warnings: $($result1.Warnings.Count)" -ForegroundColor White
} catch {
    Write-Host "   Error during validation: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Run validation WITH debug mode but without $DebugPreference set
Write-Host "`n2. Testing WITH debug mode (debug preference not set):" -ForegroundColor Yellow
try {
    $result2 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $true)
    Write-Host "   Validation completed. Errors: $($result2.ValidationErrors.Count), Warnings: $($result2.Warnings.Count)" -ForegroundColor White
    Write-Host "   Note: Debug output not visible because `$DebugPreference is not set" -ForegroundColor Gray
} catch {
    Write-Host "   Error during validation: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Run validation WITH debug mode AND $DebugPreference set to Continue
Write-Host "`n3. Testing WITH debug mode (debug preference = Continue):" -ForegroundColor Yellow
$originalDebugPreference = $DebugPreference
$DebugPreference = "Continue"  # This will make Write-Debug output visible

try {
    Write-Host "   Debug output should be visible below:" -ForegroundColor Gray
    $result3 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $true)
    Write-Host "   Validation completed. Errors: $($result3.ValidationErrors.Count), Warnings: $($result3.Warnings.Count)" -ForegroundColor White
} catch {
    Write-Host "   Error during validation: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $DebugPreference = $originalDebugPreference  # Restore original preference
}

# Test 4: Show how to capture debug output in a variable
Write-Host "`n4. Capturing debug output to a variable:" -ForegroundColor Yellow
$debugOutput = @()
try {
    # Capture debug output by temporarily redirecting Debug stream
    $result4 = [ScubaConfigValidator]::ValidateYamlFile($testConfigPath, $true) 5>&1 | Tee-Object -Variable debugOutput
    
    Write-Host "   Captured debug messages:" -ForegroundColor Gray
    $debugOutput | Where-Object { $_.GetType().Name -eq "DebugRecord" } | ForEach-Object {
        Write-Host "     DEBUG: $($_.Message)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "   Error during validation: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Testing Complete ===" -ForegroundColor Cyan
Write-Host "`nTo see debug output, you can:" -ForegroundColor White
Write-Host "  1. Set `$DebugPreference = 'Continue'" -ForegroundColor Gray
Write-Host "  2. Use the -Debug parameter if the method supported it" -ForegroundColor Gray
Write-Host "  3. Redirect stream 5 (debug stream) to capture output" -ForegroundColor Gray

# Clean up test file
if (Test-Path $testConfigPath) {
    Remove-Item $testConfigPath -Force
    Write-Host "`nCleaned up test file: $testConfigPath" -ForegroundColor Green
}