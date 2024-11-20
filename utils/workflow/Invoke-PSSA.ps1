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

	Write-Host "Testing PowerShell files with PSScriptAnalyzer..."
	Write-Output " "

	# Install PSScriptAnalyzer
	Set-PSRepository PSGallery -InstallationPolicy Trusted
	Install-Module -Name PSScriptAnalyzer -ErrorAction Stop

	# Get all PowerShell script files in the repository
	$PsFiles = Get-ChildItem -Path $RepoPath -Include *.ps1, *ps1xml, *.psc1, *.psd1, *.psm1, *.pssc, *.psrc, *.cdxml -Recurse
	# There is a dummy test file that intentionally has problems.
	# It's part of a Pester test, so I don't want this workflow to test it.
	$DummyFilePath = "D:\a\ScubaGear\ScubaGear\Testing\PesterTestFiles\DummyFail.ps1"
	$RemainingPsFiles = $PsFiles | Where-Object { $_ -ne $DummyFilePath }

	# Find the PSScriptAnalyzer config file
	$ConfigPath = Join-Path -Path $RepoPath -ChildPath Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1

	# Summary report results
	$InfoCount = 0
	$WarningCount = 0
	$ErrorCount = 0

	# Analyze each file and collect results
	foreach ($PsFile in $RemainingPsFiles) {
		Write-Warning $PsFile
		$Results = Invoke-ScriptAnalyzer -Path $PsFile -Settings $ConfigPath
		foreach ($Result in $Results) {
			Write-Output "File:     $($Result.ScriptPath)"
			Write-Output "Line:     $($Result.Line)"
			Write-Output "Severity: $($Result.Severity)"
			Write-Output "RuleName: $($Result.RuleName)"
			# Only create GitHub workflow annotation if warning or error
			# The ::error:: notation is how a workflow annotation is created
			if ($Result.Severity -eq 'Information') {
				Write-Output "Message:  $($Result.Message)"
				$InfoCount++
			}
			elseif ($Result.Severity -eq 'Warning') {
				Write-Output "::error::Message:  $($Result.Message)"
				$WarningCount++
			}
			elseif ($Result.Severity -eq 'Error') {
				Write-Output "::error::Message:  $($Result.Message)"
				$ErrorCount++
			}
			Write-Output " "
		}
	}

	# Summarize results
	Write-Output "Summary"
	Write-Output "  Errors:       $ErrorCount"
	Write-Output "  Warnings:     $WarningCount"
	Write-Output "  Information:  $InfoCount"

	# If it's important to verify the version of PSSA that is used, set DebuggingMode to true.
	# This is not run every time because it takes too long.
	if ($DebuggingMode) {
		Get-Module -ListAvailable | Where-Object { $_.Name -eq "PSScriptAnalyzer" } | Select-Object -Property Name, Version
	}

	Write-Output " "

	# Exit 1 if warnings or errors
	if (($InfoCount -gt 0) -or ($WarningCount -gt 0)) {
		Write-Output "Problems were found in the PowerShell scripts."
		exit 1
	}
	else {
		Write-Output "No problems were found in the PowerShell scripts."
	}
}