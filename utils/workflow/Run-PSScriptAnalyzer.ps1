# Install PSSA module
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSScriptAnalyzer -ErrorAction Stop

# Get all possible PowerShell files
$PsFiles = Get-ChildItem -Path ./* -Include *.ps1,*ps1xml,*.psc1,*.psd1,*.psm1,*.pssc,*.psrc,*.cdxml -Recurse

# Run PSSA for each file
$Issues = foreach ($File in $PsFiles.FullName) {
  Write-Output "Testing $File..."
	Invoke-ScriptAnalyzer -Path $File -Recurse -Settings ./Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1
}

# init and set variables
$Errors = $Warnings = $Infos = $Unknowns = 0

# Get results, types and report to GitHub Actions
foreach ($Issue in $Issues) {
	switch ($Issue.Severity) {
		{$_ -eq 'Error' -or $_ -eq 'ParseError'} {
			Write-Output "::error file=$($Issue.ScriptName),line=$($Issue.Line),col=$($Issue.Column)::$($Issue.RuleName) - $($issue.Message)"
			$Errors++
		}
		{$_ -eq 'Warning'} {
			Write-Output "::warning file=$($Issue.ScriptName),line=$($Issue.Line),col=$($Issue.Column)::$($Issue.RuleName) - $($Issue.Message)"
			$Warnings++
		}
		{$_ -eq 'Information'} {
			Write-Output "::warning file=$($Issue.ScriptName),line=$($Issue.Line),col=$($Issue.Column)::$($Issue.RuleName) - $($Issue.Message)"
			$Infos++
		}
		Default {
			Write-Output "::debug file=$($Issue.ScriptName),line=$($Issue.Line),col=$($Issue.Column)::$($Issue.RuleName) - $($Issue.Message)"
			$Unknowns++
		}
	}
}

# Report summary to GitHub Actions
If ($Unknowns -gt 0) {
	Write-Output "There were $Errors errors, $Warnings warnings, $Infos infos, and $Unknowns unknowns in total."
}
Else {
	Write-Output "There were $Errors errors, $Warnings warnings, and $Infos infos in total."
}

# Exit with error if any PSSA errors
If ($Errors -gt 0) {
	exit 1
}

# List version of PSSA used.
Get-Module -ListAvailable | Where-Object {$_.Name -eq "PSScriptAnalyzer"} | Select-Object -Property Name, Version

# Credit
# Code taken from this archived repo and modified:
# https://github.com/tigattack/VeeamDiscordNotifications
