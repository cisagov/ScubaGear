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
        [ValidateScript({Test-Path -PathType Leaf $_})]
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
    if (-not (Test-Path $Cmd -PathType Leaf)) {
        $Cmd = Join-Path -Path (Get-Location | Select-Object -ExpandProperty Path) -ChildPath $OPAFileName -ErrorAction 'Stop'
    }

    # See if the OPA executable is in the current executing directory
    if (-not (Test-Path $Cmd)) {
        throw "Open Policy Agent executable was not found. Please see the README for instructions on how to retry downloading the executable and which directory it should be placed."
    }

    # Load Utils
    if (-not (Test-Path $RegoFile -PathType Leaf)) {
        throw "Rego file not found at: $RegoFile"
    }

    $ResolvedInputFile = (Resolve-Path -Path $InputFile -ErrorAction Stop).Path
    $ResolvedRegoFile = (Resolve-Path -Path $RegoFile -ErrorAction Stop).Path

    $RegoFileObject = Get-Item $ResolvedRegoFile -ErrorAction Stop
    if ($null -eq $RegoFileObject) {
        throw "Failed to get Rego file object at: $RegoFile"
    }

    $ScubaUtils = Join-Path -Path $RegoFileObject.DirectoryName -ChildPath "Utils" -ErrorAction 'Stop'
    if (-not (Test-Path $ScubaUtils -PathType Container)) {
        throw "Rego Utils directory not found at: $ScubaUtils"
    }
    $ResolvedScubaUtils = (Resolve-Path -Path $ScubaUtils -ErrorAction Stop).Path

    $CmdArgs = @("eval", "data.$PackageName.tests", "-i", $ResolvedInputFile, "-d", $ResolvedRegoFile, "-d", $ResolvedScubaUtils, "-f", "values")

    Write-Debug "OPA Command: $Cmd"
    Write-Debug "OPA Arguments: $($CmdArgs -join ' ')"
    Write-Debug "InputFile: $ResolvedInputFile"
    Write-Debug "RegoFile: $ResolvedRegoFile"
    Write-Debug "ScubaUtils: $ResolvedScubaUtils"
    Write-Debug "PackageName: $PackageName"

    $RegoOutput = Invoke-ExternalCmd -LiteralPath $Cmd -PassThruArgs $CmdArgs | Out-String -ErrorAction 'Stop' | ConvertFrom-Json -ErrorAction 'Stop'
    $RegoOutput
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

    $Process = [System.Diagnostics.Process]::new()
    $Process.StartInfo = $ProcessStartInfo
    try {
        $ProcessStarted = $Process.Start()
        if (-not $ProcessStarted) {
            throw "Failed to start process '$LiteralPath'. The process returned false on Start()."
        }
    }
    catch {
        throw "Failed to start process '$LiteralPath': $($_.Exception.Message)"
    }

    # Read streams asynchronously to avoid deadlocks
    $stdOutTask = $Process.StandardOutput.ReadToEndAsync()
    $stdErrTask = $Process.StandardError.ReadToEndAsync()

    $Process.WaitForExit()

    $StdOut = ""
    $StdErr = ""

    try {
        $StdOut = $stdOutTask.Result
    }
    catch {
        Write-Verbose "Failed to read StandardOutput: $($_.Exception.Message)"
    }

    try {
        $StdErr = $stdErrTask.Result
    }
    catch {
        Write-Verbose "Failed to read StandardError: $($_.Exception.Message)"
    }

    if ($Process.ExitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($StdErr)) {
            $StdErr = "Unknown error from external command."
        }
        throw "Program '$LiteralPath' failed with exit code $($Process.ExitCode): $StdErr"
    }

    if (-not [string]::IsNullOrWhiteSpace($StdErr)) {
        Write-Verbose "External command stderr: $StdErr"
    }

    return $StdOut
}

Export-ModuleMember -Function @(
    'Invoke-Rego'
)
