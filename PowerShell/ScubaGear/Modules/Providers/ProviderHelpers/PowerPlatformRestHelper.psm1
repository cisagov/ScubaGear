. (Join-Path -Path $PSScriptRoot -ChildPath "MsalHelper.ps1")

function Get-PowerPlatformBaseUrl {
    <#
    .SYNOPSIS
        Returns the BAP API base URL for the given M365 environment.
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
        "commercial" { return "https://api.bap.microsoft.com" }
        "gcc"        { return "https://gov.api.bap.microsoft.us" }
        "gcchigh"    { return "https://high.api.bap.microsoft.us" }
        "dod"        { return "https://api.appsplatform.us" }
    }
}

function Get-PowerPlatformScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Power Platform API access.
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
        "commercial" { return "https://service.powerapps.com//.default" }
        "gcc"        { return "https://gov.service.powerapps.us//.default" }
        "gcchigh"    { return "https://high.service.powerapps.us//.default" }
        "dod"        { return "https://service.apps.appsplatform.us//.default" }
    }
}

function Get-PowerPlatformAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for Power Platform API using certificate authentication.
    .DESCRIPTION
        Uses MSAL (Microsoft.Identity.Client) ConfidentialClientApplication to acquire a token
        scoped to the Power Platform BAP API.
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

    $Scope = Get-PowerPlatformScope -M365Environment $M365Environment

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
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
                throw "Failed to acquire Power Platform access token: $($_.Exception.Message)"
            }
            Write-Warning "Power Platform token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

function Get-PowerPlatformAccessTokenInteractive {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for Power Platform API using interactive browser authentication.
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

    $Scope = Get-PowerPlatformScope -M365Environment $M365Environment

    # Azure PowerShell well-known client ID - broadly pre-authorized across Microsoft services
    $ClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    $RedirectUri = "http://localhost"

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
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
                throw "Failed to acquire Power Platform access token interactively: $($_.Exception.Message)"
            }
            Write-Warning "Power Platform token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

function Invoke-PowerPlatformRestMethod {
    <#
    .SYNOPSIS
        Invokes a Power Platform BAP REST API method.
    .DESCRIPTION
        Wrapper for making authenticated requests to the Power Platform BAP API.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [string]$Method = "GET",

        [Parameter(Mandatory = $false)]
        [string]$Body = $null
    )

    $Uri = "$BaseUrl$Endpoint"
    $Headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $Params = @{
        Uri         = $Uri
        Method      = $Method
        Headers     = $Headers
        ErrorAction = "Stop"
    }

    if ($Body) {
        $Params.Body = $Body
    }

    try {
        $Response = Invoke-RestMethod @Params
        return $Response
    }
    catch {
        throw "Power Platform REST API call failed: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformTenantSettingsRest {
    <#
    .SYNOPSIS
        Gets Power Platform tenant settings via REST API.
    .DESCRIPTION
        Replaces Get-TenantSettings cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/listTenantSettings?api-version=2023-06-01"

    try {
        $Response = Invoke-PowerPlatformRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "POST"
        return $Response
    }
    catch {
        throw "Failed to get Power Platform Tenant Settings: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformEnvironmentsRest {
    <#
    .SYNOPSIS
        Gets Power Platform environments via REST API.
    .DESCRIPTION
        Replaces Get-AdminPowerAppEnvironment cmdlet with direct BAP REST API call.
        Transforms response into the format expected by Rego policies.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2023-06-01"

    try {
        $Response = Invoke-PowerPlatformRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"

        $Environments = @()
        if ($Response.value) {
            foreach ($Env in $Response.value) {
                $Environments += [PSCustomObject]@{
                    EnvironmentName = $Env.name
                    DisplayName     = $Env.properties.displayName
                    IsDefault       = $Env.properties.isDefault
                    Location        = $Env.location
                    EnvironmentType = $Env.properties.environmentSku
                    CreatedTime     = $Env.properties.createdTime
                }
            }
        }

        return $Environments
    }
    catch {
        throw "Failed to get Power Platform Environments: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformDlpPoliciesRest {
    <#
    .SYNOPSIS
        Gets Power Platform DLP policies via REST API.
    .DESCRIPTION
        Replaces Get-DlpPolicy cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2016-11-01"

    try {
        $Response = Invoke-PowerPlatformRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"

        # The 2016-11-01 endpoint returns a nested schema (properties.definition) rather than
        # the flat schema (displayName, environmentType, environments at the top level) that
        # Rego expects. Normalize the response to match the flat schema.
        $NormalizedPolicies = foreach ($Policy in $Response.value) {
            $Def = $Policy.properties.definition
            $Ef = $Def.constraints.environmentFilter1

            if ($null -eq $Ef) {
                $EnvType = "AllEnvironments"
                $Environments = @()
            }
            elseif ($Ef.parameters.filterType -eq "include") {
                $EnvType = "OnlyEnvironments"
                $Environments = @($Ef.parameters.environments)
            }
            else {
                $EnvType = "ExceptEnvironments"
                $Environments = @($Ef.parameters.environments)
            }

            [PSCustomObject]@{
                name            = $Policy.name
                displayName     = $Policy.properties.displayName
                environmentType = $EnvType
                environments    = $Environments
                connectorGroups = @()
            }
        }

        return [PSCustomObject]@{ value = @($NormalizedPolicies) }
    }
    catch {
        throw "Failed to get Power Platform DLP Policies: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformTenantIsolationRest {
    <#
    .SYNOPSIS
        Gets Power Platform tenant isolation policy via REST API.
    .DESCRIPTION
        Replaces Get-PowerAppTenantIsolationPolicy cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        # TenantId is required - it is a path segment in the PowerPlatform.Governance endpoint.
        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )

    # Correct endpoint sourced from Microsoft.PowerApps.Administration.PowerShell v2.0.216
    # provider: PowerPlatform.Governance/v1, not Microsoft.BusinessAppPlatform
    $Endpoint = "/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01"

    try {
        $Response = Invoke-PowerPlatformRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
        return $Response
    }
    catch {
        throw "Failed to get Power Platform Tenant Isolation Policy: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Initialize-Msal',
    'Get-PowerPlatformBaseUrl',
    'Get-PowerPlatformScope',
    'Get-PowerPlatformAccessToken',
    'Get-PowerPlatformAccessTokenInteractive',
    'Invoke-PowerPlatformRestMethod',
    'Get-PowerPlatformTenantSettingsRest',
    'Get-PowerPlatformEnvironmentsRest',
    'Get-PowerPlatformDlpPoliciesRest',
    'Get-PowerPlatformTenantIsolationRest'
)
