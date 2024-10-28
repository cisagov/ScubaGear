# Install PSScriptAnalyzer
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
# Import the PSScriptAnalyzer module
Import-Module PSScriptAnalyzer

# Get all PowerShell script files in the repository
$psFiles = Get-ChildItem -Path ./*  -Include *.ps1,*ps1xml,*.psc1,*.psd1,*.psm1,*.pssc,*.psrc,*.cdxml -Recurse

# Analyze each file and collect results
$results = foreach ($file in $psFiles) {
    Invoke-ScriptAnalyzer -Path $file.FullName -Settings ./Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1
}

# Report results
if ($results) {
    $hasErrors = $false
    $results | ForEach-Object {
        Write-Host "File: $($_.ScriptPath)"
        Write-Host "Line: $($_.Line)"
        Write-Host "Severity: $($_.Severity)"
        Write-Host "Message: $($_.Message)"
        Write-Host "RuleName: $($_.RuleName)"
        Write-Host "--------------------------"

        if ($_.Severity -eq 'Error') {
            $hasErrors = $true
        }
    }

    if ($hasErrors) {
        Write-Host "Errors were found in the PowerShell scripts." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "No issues found in the PowerShell scripts."
}

Write-Output "`n`n"

# List version of PSSA used.
Get-Module -ListAvailable | Where-Object {$_.Name -eq "PSScriptAnalyzer"} | Select-Object -Property Name, Version

# Exit with error if any PSSA errors
If ($Errors -gt 0) {
	exit 1
}