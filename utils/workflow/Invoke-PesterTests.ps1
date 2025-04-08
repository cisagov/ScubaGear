function Invoke-PesterTests {
    <#
        .SYNOPSIS
            Calls the Invoke-Pester command to test the PowerShell files in some location.
        .PARAMETER Path
            The path to the PowerShell.  This can be a directory or a file.
        .PARAMETER ExcludePath
            The path to any Pester tests to exclude.  The intention is to avoid running the PSSA tests again, as they are run in a previous step in the workflow.
    #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
        [Parameter(Mandatory = $false)]
        [string]
        $ExcludePath
	)

    # The -PassThru parameter is what allows the output to be passed to the $result output.
    # https://pester.dev/docs/commands/Invoke-Pester#-passthru
    $result = Try {
        if ([string]::IsNullOrEmpty($ExcludePath)) {
            Write-Warning "Running Pester tests on the path..."
            # Don't use the exclude path if it's not passed in.
            Invoke-Pester -Output 'Detailed' -Path $Path -PassThru
        }
        else {
            Write-Warning "Running Pester tests while excluding..."
            Import-Module Pester -Force
            $Configuration = New-PesterConfiguration
            $Configuration.Run.Path = $Path
            # Note: This exclude path doesn't work.  For reasons unknown, it doesn't exclude
            # the file that is passed in here.
            # Info about configuration can be found here:
            # https://pester.dev/docs/usage/configuration
            # Even though this isn't working, I am leaving this code in, hoping to figure this
            # out eventually.
            $Configuration.Run.ExcludePath = $ExcludePath
            $Configuration.Run.PassThru = $true
            $Configuration.Output.Verbosity = 'Detailed'
            Invoke-Pester -Configuration $Configuration
        }
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