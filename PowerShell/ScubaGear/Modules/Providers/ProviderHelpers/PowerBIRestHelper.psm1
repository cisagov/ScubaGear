. (Join-Path -Path $PSScriptRoot -ChildPath "MsalHelper.ps1")

function Get-PowerBIBaseUrl {
    <#
    .SYNOPSIS
        Returns the Power BI Admin API base URL for the given M365 environment.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        "commercial" { return "https://api.powerbi.com" }
        "gcc"        { return "https://api.powerbigov.us" }
        "gcchigh"    { return "https://api.high.powerbigov.us" }
        "dod"        { return "https://app.mil.powerbigov.us" }
    }
}

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

    # Set the correct scope for the Power BI Admin API based on the environment
    switch ($M365Environment) {
        "commercial" { return "https://analysis.windows.net/powerbi/api/.default" }
        "gcc"        { return "https://analysis.usgovcloudapi.net/powerbi/api/.default" }
        "gcchigh"    { return "https://high.analysis.usgovcloudapi.net/powerbi/api/.default" }
        "dod"        { return "https://mil.analysis.usgovcloudapi.net/powerbi/api/.default" }
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
                throw "Failed to acquire Power BI access token: $($_.Exception.Message)"
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
                throw "Failed to acquire Power BI access token interactively: $($_.Exception.Message)"
            }
            Write-Warning "Power BI token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

Export-ModuleMember -Function @(
    'Get-PowerBIBaseUrl',
    'Get-PowerBIScope',
    'Get-PowerBIAccessToken',
    'Get-PowerBIAccessTokenInteractive'
)