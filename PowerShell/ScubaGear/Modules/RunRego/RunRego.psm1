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

    $RegoFileObject = Get-Item $RegoFile -ErrorAction Stop
    if ($null -eq $RegoFileObject) {
        throw "Failed to get Rego file object at: $RegoFile"
    }

    $ScubaUtils = Join-Path -Path $RegoFileObject.DirectoryName -ChildPath "Utils" -ErrorAction 'Stop'
    if (-not (Test-Path $ScubaUtils -PathType Container)) {
        throw "Rego Utils directory not found at: $ScubaUtils"
    }

    $CmdArgs = @("eval", "data.$PackageName.tests", "-i", $InputFile, "-d", $RegoFile, "-d", $ScubaUtils, "-f", "values")

    Write-Debug "OPA Command: $Cmd"
    Write-Debug "OPA Arguments: $($CmdArgs -join ' ')"
    Write-Debug "InputFile: $InputFile"
    Write-Debug "RegoFile: $RegoFile"
    Write-Debug "ScubaUtils: $ScubaUtils"
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

    foreach ($Arg in $PassThruArgs) {
        $null = $ProcessStartInfo.ArgumentList.Add([string]$Arg)
    }

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

    $StdOut = ""
    $StdErr = ""

    if ($null -ne $Process.StandardOutput) {
        $StdOut = $Process.StandardOutput.ReadToEnd()
    }

    if ($null -ne $Process.StandardError) {
        $StdErr = $Process.StandardError.ReadToEnd()
    }

    $Process.WaitForExit()

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
