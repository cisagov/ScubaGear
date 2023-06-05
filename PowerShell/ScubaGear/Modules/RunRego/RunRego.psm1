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
        # PowerShell 5.1 compatible Windows OS check
        if ("Windows_NT" -eq $Env:OS) {
            $Cmd = Join-Path -Path $OPAPath -ChildPath "opa_windows_amd64.exe" -ErrorAction 'Stop'
        }
        else {
            # Permissions: chmod 755 ./opa
            $Cmd = Join-Path -Path $OPAPath -ChildPath "opa" -ErrorAction 'Stop'
        }

        # Load Utils
        $RegoFileObject = Get-Item $RegoFile
        $ScubaUtils = Join-Path -Path $RegoFileObject.DirectoryName -ChildPath "Utils"
        $CmdArgs = @("eval", "data.$PackageName.tests", "-i", $InputFile, "-d", $RegoFile, "-d", $ScubaUtils, "-f", "values")
        $TestResults = $(& $Cmd @CmdArgs) | Out-String -ErrorAction 'Stop' | ConvertFrom-Json -ErrorAction 'Stop'
        $TestResults
    }
    catch {
        throw "Error calling the OPA executable: $($_)"
    }
}

Export-ModuleMember -Function @(
    'Invoke-Rego'
)
