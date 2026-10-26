Import-Module -Name $PSScriptRoot/../Utility/ScubaLogging.psm1 -Function Write-ScubaLog

function Invoke-Rego {
    <#
    .Description
    This function runs the specifed BaselineName rego file against the
    ProviderSettings.json using the specified OPA executable
    Returns an OPA Rego output PSObject array
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        [string]
        $InputFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RegoFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageName,

        # The path to the OPA executable. Defaults to the current directory.
        [ValidateNotNullOrEmpty()]
        [string]
        $OPAPath = $PSScriptRoot
    )
    # For MacOS/Linux give OPA execute permissions: chmod 755 ./opa
    $OPAFileName = if ("Windows_NT" -eq $Env:OS) {"opa_windows_amd64.exe"} else {"opa"}
    $Cmd = Join-Path -Path $OPAPath -ChildPath $OPAFileName  -ErrorAction 'Stop'

    # Set backup execution path to be current directory if ScubaTools path fails
    if (-not (Test-Path -LiteralPath $Cmd -PathType Leaf)) {
        $Cmd = Join-Path -Path (Get-Location | Select-Object -ExpandProperty Path) -ChildPath $OPAFileName -ErrorAction 'Stop'
    }

    # See if the OPA executable is in the current executing directory
    if (-not (Test-Path -LiteralPath $Cmd)) {
        throw "Open Policy Agent executable was not found. Please see the README for instructions on how to retry downloading the executable and which directory it should be placed."
    }

    # Load Utils
    if (-not (Test-Path -LiteralPath $RegoFile -PathType Leaf)) {
        throw "Rego file not found at: $RegoFile"
    }

    # LiteralPath so input/output paths containing wildcard characters (e.g. []) resolve correctly.
    $ResolvedInputFile = (Resolve-Path -LiteralPath $InputFile -ErrorAction Stop).Path
    $ResolvedRegoFile = (Resolve-Path -LiteralPath $RegoFile -ErrorAction Stop).Path

    $RegoFileObject = Get-Item -LiteralPath $ResolvedRegoFile -ErrorAction Stop
    if ($null -eq $RegoFileObject) {
        throw "Failed to get Rego file object at: $RegoFile"
    }

    $ScubaUtils = Join-Path -Path $RegoFileObject.DirectoryName -ChildPath "Utils" -ErrorAction 'Stop'
    if (-not (Test-Path -LiteralPath $ScubaUtils -PathType Container)) {
        throw "Rego Utils directory not found at: $ScubaUtils"
    }
    $ResolvedScubaUtils = (Resolve-Path -LiteralPath $ScubaUtils -ErrorAction Stop).Path

    $CmdArgs = @("eval", "data.$PackageName.tests", "-i", $ResolvedInputFile, "-d", $ResolvedRegoFile, "-d", $ResolvedScubaUtils, "-f", "values")

    Write-Debug "OPA Command: $Cmd"
    Write-Debug "OPA Arguments: $($CmdArgs -join ' ')"
    Write-Debug "InputFile: $ResolvedInputFile"
    Write-Debug "RegoFile: $ResolvedRegoFile"
    Write-Debug "ScubaUtils: $ResolvedScubaUtils"
    Write-Debug "PackageName: $PackageName"

    $RegoOutput = Invoke-ExternalCmd -LiteralPath $Cmd -PassThruArgs $CmdArgs | Out-String -ErrorAction 'Stop' | ConvertFrom-Json -ErrorAction 'Stop'
    $RegoOutput

    # # Test code Below (Delete after beta testing)
    # ########################
    # $ShellPath = (Get-Process -Id $PID).Path
    # # $Script = '[Console]::Out.WriteLine("Some message on stdout"); exit 2'
    # $Script = '[Console]::Error.WriteLine("Some message on stderr"); exit 2'

    # $Encoded = [Convert]::ToBase64String(
    #     [Text.Encoding]::Unicode.GetBytes($Script)
    # )

    # Invoke-ExternalCmd -LiteralPath $ShellPath -PassThruArgs @(
    #     '-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded
    # )
    # ####################### End Test code
}

function Invoke-ExternalCmd{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,
        [Parameter(ValueFromRemainingArguments=$true)]
        $PassThruArgs
    )

    $ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $ProcessStartInfo.FileName = $LiteralPath
    $ProcessStartInfo.UseShellExecute = $false
    $ProcessStartInfo.RedirectStandardOutput = $true
    $ProcessStartInfo.RedirectStandardError = $true
    $ProcessStartInfo.CreateNoWindow = $true

    $EscapedArgs = foreach ($Arg in $PassThruArgs) {
        $ArgText = [string]$Arg
        if ($ArgText -match '[\s"]') {
            '"' + ($ArgText -replace '"', '\\"') + '"'
        }
        else {
            $ArgText
        }
    }
    $ProcessStartInfo.Arguments = ($EscapedArgs -join ' ')

    $ExecutablePath = (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
    $ProcessStartInfo.FileName = $ExecutablePath
    Write-ScubaLog -Message "$ExecutablePath $($ProcessStartInfo.Arguments)" -Level "Info" -Source "Invoke-ExternalCmd"

    $Process = [System.Diagnostics.Process]::new()
    try {
        $Process.StartInfo = $ProcessStartInfo
        try {
            if (-not $Process.Start()) {
                throw 'The process returned false on Start().'
            }
        }
        catch {
            $Message = "Failed to start process '$ExecutablePath': $($_.Exception.Message)"
            throw $Message
        }

        # Start both reads before waiting to avoid deadlocks on full output buffers.
        # Attempt both streams even if starting or completing one read fails.
        $StreamErrors = @()
        $ReadTasks = @{}
        $Output = @{ StandardOutput = ''; StandardError = '' }
        foreach ($Stream in @('StandardOutput', 'StandardError')) {
            try {
                $ReadTasks[$Stream] = $Process.$Stream.ReadToEndAsync()
            }
            catch {
                $StreamErrors += "Failed to read ${Stream}: $($_.Exception.Message)"
            }
        }

        foreach ($Stream in @('StandardOutput', 'StandardError')) {
            if ($ReadTasks.ContainsKey($Stream)) {
                try {
                    $Output[$Stream] = $ReadTasks[$Stream].GetAwaiter().GetResult()
                }
                catch {
                    $StreamErrors += "Failed to read ${Stream}: $($_.Exception.Message)"
                }
            }
        }

        $Process.WaitForExit()
        $StdOut = $Output.StandardOutput
        $StdErr = $Output.StandardError

        # If the process exited with a non-zero exit code or if there were any errors reading the streams, log the error and throw an exception.
        if ($Process.ExitCode -ne 0 -or $StreamErrors.Count -gt 0) {
            $Message = if ($Process.ExitCode -ne 0) {
                "Program '$ExecutablePath' failed with exit code $($Process.ExitCode)."
            }
            else {
                "Failed to capture output from program '$ExecutablePath' (exit code 0)."
            }
            if ($StreamErrors.Count -gt 0) {
                $Message += "`n" + ($StreamErrors -join "`n")
            }
            if (-not [string]::IsNullOrWhiteSpace($StdErr)) {
                $Message += "`nStandard error:`n$StdErr"
            }
            if (-not [string]::IsNullOrWhiteSpace($StdOut)) {
                $Message += "`nStandard output:`n$StdOut"
            }
            if ($StreamErrors.Count -eq 0 -and [string]::IsNullOrWhiteSpace($StdErr) -and
                [string]::IsNullOrWhiteSpace($StdOut)) {
                $Message += "`nNo output was captured from either stream."
            }
            throw $Message
        }

        return $StdOut
    }
    finally {
        $Process.Dispose()
    }
}

Export-ModuleMember -Function @(
    'Invoke-Rego',
    'Invoke-ExternalCmd'
)
