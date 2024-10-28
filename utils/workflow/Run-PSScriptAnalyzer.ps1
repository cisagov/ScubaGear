# Install PSScriptAnalyzer
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
# Import the PSScriptAnalyzer module
Import-Module PSScriptAnalyzer

# Get all PowerShell script files in the repository
$PsFiles = Get-ChildItem -Path ./*  -Include *.ps1, *ps1xml, *.psc1, *.psd1, *.psm1, *.pssc, *.psrc, *.cdxml -Recurse

# Analyze each file and collect results
$Results = foreach ($PsFile in $PsFiles) {
	Invoke-ScriptAnalyzer -Path $PsFile.FullName -Settings ./Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1
}

# Report results
if ($Results) {
	$HasWarnings = $false
	$HasErrors = $false
	$results | ForEach-Object {
		Write-Output "File: $($_.ScriptPath)"
		Write-Output "Line: $($_.Line)"
		Write-Output "Severity: $($_.Severity)"
		Write-Output "Message: $($_.Message)"
		Write-Output "RuleName: $($_.RuleName)"
		Write-Output "--------------------------"

		if ($_.Severity -eq 'Warning') {
			$HasWarnings = $true
		}
		elseif ($_.Severity -eq 'Error') {
			$HasErrors = $true
		}
	}
	if ($HasWarnings -or $HasErrors) {
		Write-Output "Warnings and/or errors were found in the PowerShell scripts." -ForegroundColor Red
		exit 1
	}
}
else {
	Write-Output "No warnings or errors were found in the PowerShell scripts."
}

Write-Output "`n`n"

# List version of PSSA used.
Get-Module -ListAvailable | Where-Object { $_.Name -eq "PSScriptAnalyzer" } | Select-Object -Property Name, Version

# Exit with error if any PSSA errors
If ($Errors -gt 0) {
	exit 1
}