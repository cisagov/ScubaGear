function Invoke-ScriptAnalyzer {
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
	
	Write-Host "Testing PowerShell code with PSScript Analyzer..."

	# Install PSScriptAnalyzer
	Set-PSRepository PSGallery -InstallationPolicy Trusted
	Install-Module -Name PSScriptAnalyzer -ErrorAction Stop

	# Get all PowerShell script files in the repository
	$PsFiles = Get-ChildItem -Path $RepoPath -Include *.ps1, *ps1xml, *.psc1, *.psd1, *.psm1, *.pssc, *.psrc, *.cdxml -Recurse

	# Find the PSScriptAnalyzer config file
	$ConfigPath = Join-Path -Path $RepoPath -ChildPath Testing/Linting/PSSA/.powershell-psscriptanalyzer.psd1
	# Write-Host "ConfigPath"
	# Write-Host $ConfigPath
	# cat $ConfigPath

	# Analyze each file and collect results
	$Results = foreach ($PsFile in $PsFiles) {
		Write-Host "PsFile"
		Write-Host $PsFile.FullName
		cat $PsFile
		# Invoke-ScriptAnalyzer -Path $PsFile -Settings $ConfigPath
		Write-Host "after"
	}

	Write-Output "test3"

	# Report results
	$InfoCount = 0
	$WarningCount = 0
	$ErrorCount = 0
	foreach ($Result in $Results) {
		Write-Output "File:     $($Result.ScriptPath)"
		Write-Output "Line:     $($Result.Line)"
		Write-Output "Severity: $($Result.Severity)"
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
		Write-Output "RuleName: $($Result.RuleName)"
		Write-Output "--------------------------"
	}

	# Summarize results
	Write-Output "Summary"
	Write-Output "Informations: $InfoCount"
	Write-Output "Warnings:     $WarningCount"
	Write-Output "Errors:       $ErrorCount"

	# If it's important to verify the version of PSSA that is used, set DebuggingMode to true.
	# This is not run every time because it takes too long.
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