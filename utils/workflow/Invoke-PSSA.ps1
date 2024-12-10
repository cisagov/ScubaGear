function Invoke-PSSA {
	<#
		.DESCRIPTION
			Allows a GitHub workflow to install and use PSScriptAnalyzer (PSSA).
		.PARAMETER DebuggingMode
			When the debug parameter is true, extra debugging information is available.
		.PARAMETER RepoPath
			The path to the repo where PowerShell files will be found and analyzed.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[boolean]
		$DebuggingMode,
		[Parameter(Mandatory = $true)]
		[string]
		$RepoPath
	)

	Write-Warning "Testing PowerShell files with PSScriptAnalyzer..."
	Write-Warning " "

	# Install PSScriptAnalyzer
	Set-PSRepository PSGallery -InstallationPolicy Trusted
	Install-Module -Name PSScriptAnalyzer -ErrorAction Stop

	# Get all PowerShell script files in the repository
	# There is a dummy test file that intentionally has problems.  It's part of a 
	# Pester test, so I don't want this workflow to test it.  Hence the exclude.
	$PsFiles = Get-ChildItem -Path $RepoPath -Include *.ps1, *ps1xml, *.psc1, *.psd1, *.psm1, *.pssc, *.psrc, *.cdxml -Exclude "DummyFail.ps1" -Recurse

	# Find the PSScriptAnalyzer config file
	$ConfigPath = Join-Path -Path $RepoPath -ChildPath Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1

	# Summary report results
	$InfoCount = 0
	$WarningCount = 0
	$ErrorCount = 0

	# Analyze each file and collect results
	foreach ($PsFile in $PsFiles) {
		$Results = Invoke-ScriptAnalyzer -Path $PsFile -Settings $ConfigPath
		foreach ($Result in $Results) {
			Write-Warning "File:     $($Result.ScriptPath)"
			Write-Warning "Line:     $($Result.Line)"
			Write-Warning "Severity: $($Result.Severity)"
			Write-Warning "RuleName: $($Result.RuleName)"
			# Only create GitHub workflow annotation if warning or error
			# The ::error:: notation is how a workflow annotation is created
			if ($Result.Severity -eq 'Information') {
				Write-Warning "Message:  $($Result.Message)"
				$InfoCount++
			}
			elseif ($Result.Severity -eq 'Warning') {
				Write-Warning "::error::Message:  $($Result.Message)"
				$WarningCount++
			}
			elseif ($Result.Severity -eq 'Error') {
				Write-Warning "::error::Message:  $($Result.Message)"
				$ErrorCount++
			}
			Write-Warning " "
		}
	}

	# Summarize results
	Write-Warning "Summary"
	Write-Warning "  Errors:       $ErrorCount"
	Write-Warning "  Warnings:     $WarningCount"
	Write-Warning "  Information:  $InfoCount"

	# If it's important to verify the version of PSSA that is used, set DebuggingMode to true.
	# This is not run every time because it takes too long.
	if ($DebuggingMode) {
		Get-Module -ListAvailable | Where-Object { $_.Name -eq "PSScriptAnalyzer" } | Select-Object -Property Name, Version
	}

	Write-Warning " "

	# Exit 1 if warnings or errors
	if (($ErrorCount -gt 0) -or ($WarningCount -gt 0)) {
		Write-Warning "Problems were found in the PowerShell scripts."
		exit 1
	}
	else {
		Write-Warning "No problems were found in the PowerShell scripts."
	}
}