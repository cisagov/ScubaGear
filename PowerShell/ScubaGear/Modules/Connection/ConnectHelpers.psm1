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

. (Join-Path -Path $PSScriptRoot -ChildPath "../Providers/ProviderHelpers/MsalHelper.ps1")

function Get-PowerBIScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Power BI API access.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )
    if ($M365Environment -in @("commercial", "gcc")) {
        return "https://analysis.windows.net/powerbi/api/.default"
    }
    elseif ($M365Environment -eq "gcchigh") {
        return "https://high.analysis.usgovcloudapi.net/powerbi/api/.default"
    }
    else {
        return "https://mil.analysis.usgovcloudapi.net/powerbi/api/.default"
    }
}

function Get-PowerBIAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for the Power BI Admin API using certificate authentication.
    .DESCRIPTION
        Uses MSAL (Microsoft.Identity.Client) ConfidentialClientApplication to acquire a token
        scoped to the Power BI Admin API.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $true)]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    Initialize-Msal

    $Scope = Get-PowerBIScope -M365Environment $M365Environment

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") }    { "https://login.microsoftonline.us/$Tenant" }
    }

    # Load certificate from store (try CurrentUser first, then LocalMachine)
    $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $Certificate) {
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    }
    if (-not $Certificate) {
        throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            $MsalApp = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                WithCertificate($Certificate).
                WithAuthority($Authority).
                Build()

            $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@($Scope)).ExecuteAsync().GetAwaiter().GetResult()
            return $TokenResult.AccessToken
        }
        catch {
            if ($Attempt -ge $MaxAttempts) {
                Write-Warning "Failed to acquire Power BI access token after $MaxAttempts attempts"
                throw
            }
            Write-Warning "Power BI token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

function Get-PowerBIAccessTokenInteractive {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for the Power BI Admin API using interactive browser authentication.
    .DESCRIPTION
        Uses MSAL (Microsoft.Identity.Client) PublicClientApplication to acquire a token via
        interactive browser sign-in.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    Initialize-Msal

    $Scope = Get-PowerBIScope -M365Environment $M365Environment

    # Azure PowerShell well-known client ID - broadly pre-authorized across Microsoft services
    $ClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    $RedirectUri = "http://localhost"

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") }    { "https://login.microsoftonline.us/$Tenant" }
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            $MsalApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                WithAuthority($Authority).
                WithRedirectUri($RedirectUri).
                Build()

            $Scopes = [string[]]@($Scope)
            $TokenResult = $MsalApp.AcquireTokenInteractive($Scopes).
                WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).
                ExecuteAsync().GetAwaiter().GetResult()

            return $TokenResult.AccessToken
        }
        catch {
            if ($Attempt -ge $MaxAttempts) {
                Write-Warning "Failed to acquire Power BI access token after $MaxAttempts attempts"
                throw
            }
            Write-Warning "Power BI token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

function Connect-PowerBIHelper {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for the Power BI Admin API.
    .DESCRIPTION
        Acquires the token via certificate (service principal) or interactive browser sign-in,
        depending on whether ServicePrincipalParams are supplied. An optional Tenant parameter
        can be provided to bypass the Graph lookup for interactive authentication.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [hashtable]$ServicePrincipalParams,

        [Parameter(Mandatory = $false)]
        [string]$Tenant
    )

    if ($ServicePrincipalParams.CertThumbprintParams) {
        return Get-PowerBIAccessToken `
            -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
            -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
            -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
            -M365Environment $M365Environment
    }
    else {
        if ([string]::IsNullOrEmpty($Tenant)) {
            Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "../Utility/Utility.psm1") -Function Invoke-GraphDirectly
            $TenantDetails = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value
            $Tenant = ($TenantDetails.VerifiedDomains | Where-Object { $_.IsInitial }).Name
        }
        return Get-PowerBIAccessTokenInteractive `
            -Tenant $Tenant `
            -M365Environment $M365Environment
    }
}

Export-ModuleMember -Function @(
    'Connect-GraphHelper',
    'Connect-EXOHelper',
    'Connect-DefenderHelper',
    'Connect-PowerBIHelper'
)
