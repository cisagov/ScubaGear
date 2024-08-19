function Invoke-Rego {
    <#
    .Description
    This function runs the specifed BaselineName rego file against the
    ProviderSettings.json using the specified OPA executable
    Returns a OPA TestResults PSObject Array
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
    try {
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
        $RegoFileObject = Get-Item $RegoFile
        $ScubaUtils = Join-Path -Path $RegoFileObject.DirectoryName -ChildPath "Utils"
        $CmdArgs = @("eval", "data.$PackageName.tests", "-i", $InputFile, "-d", $RegoFile, "-d", $ScubaUtils, "-f", "values")
        $TestResults = Invoke-ExternalCmd -LiteralPath $Cmd -PassThruArgs $CmdArgs | Out-String -ErrorAction 'Stop' | ConvertFrom-Json -ErrorAction 'Stop'
        $TestResults
    }
    catch {
        throw "Error calling the OPA executable: $($_)"
    }
}

function Invoke-ExternalCmd{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,
        [Parameter(ValueFromRemainingArguments=$true)]
        $PassThruArgs
    )

    & $LiteralPath $PassThruArgs
}

Export-ModuleMember -Function @(
    'Invoke-Rego'
)
