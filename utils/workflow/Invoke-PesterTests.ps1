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
    Write-Warning "The path to test is ${Path}."
    Write-Warning "The path to exclude is ${ExcludePath}"
    # The -PassThru parameter is what allows the output to be passed to the $result output.
    # https://pester.dev/docs/commands/Invoke-Pester#-passthru
    $result = Try {
        if ([string]::IsNullOrEmpty($ExcludePath)) {
        # Don't use the exclude path if it's not passed in.
        Invoke-Pester -Output 'Detailed' -Path $Path -PassThru
        }
        else {
            Import-Module Pester -Force
            # get default from static property
            # $Configuration = [PesterConfiguration]::Default
            $Configuration = New-PesterConfiguration
            $Configuration.Run.Path = $Path
            $Configuration.Run.ExcludePath = $ExcludePath
            $Configuration.Output = 'Detailed'
            # $Configuration = [PesterConfiguration]@{
            #     Run = @{
            #         ExcludePath = $ExcludePath
            #     }
            # }
            # Invoke-Pester -Output 'Detailed' -Path $Path -Configuration $Configuration -PassThru
            Invoke-Pester -Configuration $Configuration -PassThru
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
    Write-Warning "The results of invoking Pester are:"
    Write-Warning $result
}