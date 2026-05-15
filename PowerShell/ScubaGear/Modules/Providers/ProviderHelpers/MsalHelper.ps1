function Initialize-Msal {
    <#
    .SYNOPSIS
        Ensures the MSAL (Microsoft.Identity.Client) assembly is loaded and types are resolvable.
    .DESCRIPTION
        The Microsoft.Graph.Authentication module loads the MSAL assembly, but PowerShell cannot
        resolve the types via [TypeName] syntax until Add-Type is called explicitly.
        This function finds the DLL from the Graph module and loads it.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    # Check if already resolvable
    try {
        $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
        return
    }
    catch {
        # Type not yet resolvable, need to load explicitly
        Write-Verbose "MSAL types not yet resolvable. Loading Microsoft.Identity.Client.dll explicitly."
    }

    $GraphModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
    if (-not $GraphModule) {
        throw "Microsoft.Graph.Authentication module is not loaded. Ensure Connect-MgGraph has been called before acquiring tokens."
    }

    $ModulePath = $GraphModule.Path | Split-Path
    $MsalDll = Get-ChildItem -Path $ModulePath -Recurse -Filter "Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $MsalDll) {
        throw "Microsoft.Identity.Client.dll not found in the Microsoft.Graph.Authentication module directory."
    }

    $Sig = Get-AuthenticodeSignature -FilePath $MsalDll.FullName
    if ($Sig.Status -ne 'Valid') {
        throw "Microsoft.Identity.Client.dll signature is not valid (status: $($Sig.Status)). Aborting MSAL load."
    }

    Add-Type -Path $MsalDll.FullName
}
