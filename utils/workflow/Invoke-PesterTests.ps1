function Invoke-PesterTests {
  <#
    .SYNOPSIS
      Calls the Invoke-Pester command to test the PowerShell files in some location.
    .PARAMETER Path
      The path to the PowerShell.  This can be a directory or a file.
  #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
  Write-Warning "The path to test is ${Path}."
  # The -PassThru parameter is what allows the output to be passed to the $result output.
  # https://pester.dev/docs/commands/Invoke-Pester#-passthru
  $result = Try {
    Invoke-Pester -Output 'Detailed' -Path $Path -PassThru
  } Catch {
    # This catches an error with the Pester tests.
    Write-Warning "An error occurred while running the Pester tests:"
    Write-Warning $_
    exit 1
  }
  # This catches an error that causes Pester not to run at all
  # (e.g., if the -Path is set to a nonexistent directory).
  if ($null -eq $result) {
    throw "The Pester tests failed to run."
  }
}