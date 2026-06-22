function Connect-GraphHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments via the Graph API.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Scopes = $null,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $GraphParams = @{
        'ErrorAction' = 'Stop';
    }

    if ($ServicePrincipalParams.CertThumbprintParams) {
        $GraphParams += @{
            CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
            ClientID              = $ServicePrincipalParams.CertThumbprintParams.AppID;
            TenantId              = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization also works here
        }
    }
    else {
        $GraphParams += @{Scopes = $Scopes; }
    }
    switch ($M365Environment) {
        "gcchigh" {
            $GraphParams += @{'Environment' = "USGov"; }
        }
        "dod" {
            $GraphParams += @{'Environment' = "USGovDoD"; }
        }
    }
    ########## New code (DELETE)
    # Initialize-Msal
    # $AssemblyDebugInfo =
    #     [AppDomain]::CurrentDomain.GetAssemblies() |
    #     Where-Object {
    #         $_.GetName().Name -like '*Identity*' -or
    #         $_.GetName().Name -like '*Graph*'
    #     } |
    #     Select-Object @{
    #         Name = 'Name'
    #         Expression = { $_.GetName().Name }
    #     }, @{
    #         Name = 'Version'
    #         Expression = { $_.GetName().Version.ToString() }
    #     }, Location |
    #     Sort-Object Name, Version, Location |
    #     Format-Table -AutoSize -Wrap |
    #     Out-String -Width 4096

    # Write-Information $AssemblyDebugInfo -InformationAction Continue
    ############
    Connect-MgGraph @GraphParams | Out-Null
}

function Connect-EXOHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments for EXO.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $EXOParams = @{
        ErrorAction = "Stop";
        ShowBanner = $false;
    }
    switch ($M365Environment) {
        "gcchigh" {
            $EXOParams += @{'ExchangeEnvironmentName' = "O365USGovGCCHigh";}
        }
        "dod" {
            $EXOParams += @{'ExchangeEnvironmentName' = "O365USGovDoD";}
        }
    }

    if ($ServicePrincipalParams.CertThumbprintParams) {
        $EXOParams += $ServicePrincipalParams.CertThumbprintParams
    }
    Connect-ExchangeOnline @EXOParams | Out-Null
}

function Connect-DefenderHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments for EXO.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $IPPSParams = @{
        'ErrorAction' = 'Stop';
        'ShowBanner' = $false;
    }
    switch ($M365Environment) {
        "gcchigh" {
            $IPPSParams += @{'ConnectionUri' = "https://ps.compliance.protection.office365.us/powershell-liveid";}
            $IPPSParams += @{'AzureADAuthorizationEndpointUri' = "https://login.microsoftonline.us/common";}
        }
        "dod" {
            $IPPSParams += @{'ConnectionUri' = "https://l5.ps.compliance.protection.office365.us/powershell-liveid";}
            $IPPSParams += @{'AzureADAuthorizationEndpointUri' = "https://login.microsoftonline.us/common";}
        }
    }
    if ($ServicePrincipalParams.CertThumbprintParams) {
        $IPPSParams += $ServicePrincipalParams.CertThumbprintParams
    }
    Connect-IPPSSession @IPPSParams | Out-Null
}

function Initialize-Msal {
    <#
    .SYNOPSIS
        Ensures the MSAL (Microsoft.Identity.Client) assembly is loaded and types are resolvable.

    .DESCRIPTION
        The Microsoft.Graph.Authentication module loads the MSAL assembly, but PowerShell cannot
        resolve the types via [TypeName] syntax until Add-Type is called explicitly.
        This function finds the DLL from the Graph module and loads it.

    .EXAMPLE
        Initialize-Msal
        Loads the MSAL assembly so that types like [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
        become resolvable in the current session.

    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    ###########################################
    # Check if MSAL type is already available
    try {
        $null = [Microsoft.Identity.Client.PublicClientApplicationBuilder]
        Write-Information "MSAL types already loaded." -InformationAction Continue
        return
    }
    catch {
        Write-Information "MSAL types not yet resolvable. Implicitly loading through Microsoft.Graph.Authentication." -InformationAction Continue
    }

    # By calling Connect-MgGraph we implicitly load MSAL through Microsoft.Graph.Authentication.
    # We are not authenticating to an actual tenant so we pass bogus parammeters and expect the cmdlet to produce an error which we ignore.
    try {
        $null = Connect-MgGraph -TenantId localhost -ClientId c2c07fbd-041e-45a0-9c13-1216e2a521dc -CertificateThumbprint 123456789B9F22EFA77A0EFF01930AD123456789 -ErrorAction Stop
    }
    catch {
        # Ignore. We expect this error.
    }

    # $LoadedGraphAuth = Get-Module Microsoft.Graph.Authentication
    # if (-not $LoadedGraphAuth) {
    #     throw "Microsoft.Graph.Authentication was not successfully loaded by Initialize-Msal."
    # }
    # Try referencing MSAL again after implicit load
    try {
        $null = [Microsoft.Identity.Client.PublicClientApplicationBuilder]
        Write-Information "MSAL loaded successfully." -InformationAction Continue
        return
    }
    catch {
        throw "MSAL types still not resolvable after implicit load."
    }
    ###########################################

    # $GraphModule = Import-LatestGraphAuthentication

    # if (-not $GraphModule) {
    #     throw "Microsoft.Graph.Authentication was imported, but the module could not be found in the current session."
    # }

    # $ModulePath = Split-Path -Path $GraphModule.Path -Parent

    # if ($PSVersionTable.PSEdition -eq "Desktop") {
    #     $DependencyFolder = Join-Path $ModulePath "Dependencies" | Join-Path -ChildPath "Desktop"
    # }
    # else {
    #     $DependencyFolder = Join-Path $ModulePath "Dependencies" | Join-Path -ChildPath "Core"
    # }

    # $MsalDll = Join-Path $DependencyFolder "Microsoft.Identity.Client.dll"

    # if (-not (Test-Path $MsalDll)) {
    #     throw "Microsoft.Identity.Client.dll was not found at expected path: $MsalDll"
    # }

    # $Signature = Get-AuthenticodeSignature -FilePath $MsalDll

    # if ($Signature.Status -ne "Valid") {
    #     throw "Microsoft.Identity.Client.dll has an invalid Authenticode signature. Status: $($Signature.Status). Path: $($MsalDll)"
    # }

    # try {
    #     Add-Type -Path $MsalDll -ErrorAction Stop
    #     $null = [Microsoft.Identity.Client.PublicClientApplicationBuilder]
    # }
    # catch {
    #     Write-Information "Microsoft.Identity.Client.dll was loaded, but MSAL type Microsoft.Identity.Client.PublicClientApplicationBuilder is still not resolvable. Path: $($MsalDll)" -InformationAction Continue
    #     throw
    # }

    # Write-Information "Successfully loaded MSAL from: $($MsalDll)" -InformationAction Continue

    ########## Old code (DELETE)
    # try {
    #     $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
    #     Write-Information "MSAL is resolvable. No need to do anything." -InformationAction Continue
    #     return
    # }
    # catch {
    #     # Type not yet resolvable, need to load explicitly
    #     Write-Information "MSAL types not yet resolvable. Loading Microsoft.Identity.Client.dll explicitly." -InformationAction Continue
    # }

    # $GraphModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
    # if (-not $GraphModule) {
    #     throw "Microsoft.Graph.Authentication module is not loaded. Ensure Connect-MgGraph has been called before acquiring tokens."
    # }

    # $ModulePath = $GraphModule.Path | Split-Path
    # $MsalDll = Get-ChildItem -Path $ModulePath -Recurse -Filter "Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Select-Object -First 1

    # if (-not $MsalDll) {
    #     throw "Microsoft.Identity.Client.dll not found in the Microsoft.Graph.Authentication module directory."
    # }

    # $Sig = Get-AuthenticodeSignature -FilePath $MsalDll.FullName
    # if ($Sig.Status -ne 'Valid') {
    #     throw "Microsoft.Identity.Client.dll signature is not valid (status: $($Sig.Status)). Aborting MSAL load."
    # }

    # Add-Type -Path $MsalDll.FullName
    # Write-Information "Loaded Microsoft.Identity.Client.dll from $($MsalDll.FullName)" -InformationAction Continue
}

function Get-MsalAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token via MSAL using certificate or interactive browser authentication.

    .DESCRIPTION
        Unified MSAL token acquisition function supporting two authentication flows:
        - ServicePrincipal: Certificate-based ConfidentialClientApplication (automated/unattended)
        - Interactive: Browser-based PublicClientApplication (user sign-in)
        PowerShell resolves the parameter set automatically based on which parameters are provided.

    .PARAMETER Scope
        The OAuth2 scope to request (e.g., "https://contoso-admin.sharepoint.com/.default").

    .PARAMETER CertificateThumbprint
        The thumbprint of the certificate to use for authentication (ServicePrincipal set).

    .PARAMETER AppID
        The Azure AD Application (Client) ID for certificate auth (ServicePrincipal set).

    .PARAMETER ClientId
        The well-known client ID to use for interactive auth (Interactive set).
        Examples: Azure PowerShell ID for Power Platform, SPO Management Shell ID for SharePoint.

    .PARAMETER Tenant
        The tenant domain or ID.

    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).

    .EXAMPLE
        Get-MsalAccessToken -Scope "https://contoso-admin.sharepoint.com/.default" `
            -CertificateThumbprint "AB12CD34EF56" -AppID "00000000-0000-0000-0000-000000000001" `
            -Tenant "contoso.onmicrosoft.com" -M365Environment "commercial"
        Acquires a certificate-based access token scoped to the SharePoint Admin API.

    .EXAMPLE
        Get-MsalAccessToken -Scope "https://contoso-admin.sharepoint.com/.default" `
            -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc" `
            -Tenant "contoso.onmicrosoft.com" -M365Environment "commercial"
        Opens a browser window for the user to sign in and acquires a SharePoint access token
        using the SPO Management Shell well-known client ID.

    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scope,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]$AppID,

        [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    Initialize-Msal

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
    }

    # Certificate-based: load certificate from store before retry loop
    if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
        $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        if (-not $Certificate) {
            $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        }
        if (-not $Certificate) {
            throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
        }
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
                $MsalApp = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                    WithCertificate($Certificate).
                    WithAuthority($Authority).
                    Build()

                $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@($Scope)).ExecuteAsync().GetAwaiter().GetResult()
            }
            else {
                $RedirectUri = "http://localhost"
                $MsalApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                    WithAuthority($Authority).
                    WithRedirectUri($RedirectUri).
                    Build()

                $TokenResult = $MsalApp.AcquireTokenInteractive([string[]]@($Scope)).
                    WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).
                    WithUseEmbeddedWebView($true).
                    ExecuteAsync().GetAwaiter().GetResult()
            }
            return $TokenResult.AccessToken
        }
        catch {
            if ($Attempt -ge $MaxAttempts) {
                Write-Warning "Failed to acquire access token after $MaxAttempts attempts"
                throw
            }
            Write-Warning "Token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

Export-ModuleMember -Function @(
    'Connect-GraphHelper',
    'Connect-EXOHelper',
    'Connect-DefenderHelper',
    'Initialize-Msal',
    'Get-MsalAccessToken'
)
