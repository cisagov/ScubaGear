# Install PSSA module
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSScriptAnalyzer -ErrorAction Stop

Get-Module -ListAvailable | Where-Object {$_.Name -eq "PSScriptAnalyzer"} | Select-Object -Property Name, Version

# Intentionally blank line.
Write-Output ""

# Get all relevant PowerShell files
$psFiles = Get-ChildItem -Path ./* -Include *.ps1,*.psm1 -Recurse

# Run PSSA
$issues = foreach ($i in $psFiles.FullName) {
	Invoke-ScriptAnalyzer -Path $i -Recurse -Settings ./Testing/Linting/MegaLinter/.powershell-psscriptanalyzer.psd1
}

# init and set variables
$errors = $warnings = $infos = $unknowns = 0

# Get results, types and report to GitHub Actions
foreach ($i in $issues) {
	switch ($i.Severity) {
		{$_ -eq 'Error' -or $_ -eq 'ParseError'} {
			Write-Output "::error file=$($i.ScriptName),line=$($i.Line),col=$($i.Column)::$($i.RuleName) - $($i.Message)"
			$errors++
		}
		{$_ -eq 'Warning'} {
			Write-Output "::warning file=$($i.ScriptName),line=$($i.Line),col=$($i.Column)::$($i.RuleName) - $($i.Message)"
			$warnings++
		}
		{$_ -eq 'Information'} {
			Write-Output "::warning file=$($i.ScriptName),line=$($i.Line),col=$($i.Column)::$($i.RuleName) - $($i.Message)"
			$infos++
		}
		Default {
			Write-Output "::debug file=$($i.ScriptName),line=$($i.Line),col=$($i.Column)::$($i.RuleName) - $($i.Message)"
			$unknowns++
		}
	}
}

# Intentionally blank line.
Write-Output ""

# Report summary to GitHub Actions
If ($unknowns -gt 0) {
	Write-Output "There were $errors errors, $warnings warnings, $infos infos, and $unknowns unknowns in total."
}
Else {
	Write-Output "There were $errors errors, $warnings warnings, and $infos infos in total."
}

# Exit with error if any PSSA errors
If ($errors -gt 0) {
	exit 1
}

# Credit
# Code taken from this archived repo and modified:
# https://github.com/tigattack/VeeamDiscordNotifications
