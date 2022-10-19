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
    [Parameter(Mandatory=$true)]
    [string]
    $InputFile,

    [Parameter(Mandatory=$true)]
    [string]
    $RegoFile,

    [Parameter(Mandatory=$true)]
    [string]
    $PackageName,

    # The path to the OPA executable. Defaults to the current directory.
    [string]
    $OPAPath = $PSScriptRoot
)

# PowerShell 5.1 compatible Windows OS check
if ("Windows_NT" -eq $Env:OS) {
    $Cmd = Join-Path -Path $OPAPath -ChildPath "opa_windows_amd64.exe"
}
else {
    # Permissions: chmod 755 ./opa
    $Cmd = Join-Path -Path $OPAPath -ChildPath "opa"
}

$CmdArgs = @("eval", "-i", $InputFile, "-d", $RegoFile, "data.$PackageName.tests", "-f", "values")
$TestResults = $(& $Cmd @CmdArgs) | Out-String | ConvertFrom-Json

$TestResults
}

Export-ModuleMember -Function @(
    'Invoke-Rego'
)
