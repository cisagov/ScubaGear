function Invoke-ScriptAnalyzer {
	<#
		.SYNOPSIS
			The purpose of this function is to allow a GitHub workflow to install and use PSScriptAnalyzer (PSSA).
		.PARAMETER DebuggingMode
			When the debug parameter is true, extra debugging information is available.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[boolean]
		$DebuggingMode
	)
	Write-Output "Testing PowerShell code with PSScript Analyzer..."

	# Install PSScriptAnalyzer
	Set-PSRepository PSGallery -InstallationPolicy Trusted
	Install-Module -Name PSScriptAnalyzer -ErrorAction Stop

	# Get all PowerShell script files in the repository
	$PsFiles = Get-ChildItem -Path ./*  -Include *.ps1, *ps1xml, *.psc1, *.psd1, *.psm1, *.pssc, *.psrc, *.cdxml -Recurse

	# Analyze each file and collect results
	$Results = foreach ($PsFile in $PsFiles) {
		Invoke-ScriptAnalyzer -Path $PsFile.FullName -Settings ./Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1
	}

	# Report results
	$InfoCount = 0
	$WarningCount = 0
	$ErrorCount = 0
	foreach ($Result in $Results) {
		Write-Output "File:     $($Result.ScriptPath)"
		Write-Output "Line:     $($Result.Line)"
		Write-Output "Severity: $($Result.Severity)"
		# Only create GitHub workflow annotation if warning or error
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
		Write-Output "RuleName: $($Result.RuleName)"
		Write-Output "--------------------------"
	}

	# Summarize results
	Write-Output "Summary"
	Write-Output "Informations: $InfoCount"
	Write-Output "Warnings:     $WarningCount"
	Write-Output "Errors:       $ErrorCount"

	# If it's important to verify the version of PSSA that is used, set DebuggingMode to true.
	# This is not run every time because it's slow.
	if ($DebuggingMode) {
		Get-Module -ListAvailable | Where-Object { $_.Name -eq "PSScriptAnalyzer" } | Select-Object -Property Name, Version
	}

	# Exit 1 if warnings or errors
	if (($InfoCount -gt 0) -or ($WarningCount -gt 0)) {
		Write-Output "Problems were found in the PowerShell scripts."
		exit 1
	}
	else {
		Write-Output "No problems were found in the PowerShell scripts."
	}
}