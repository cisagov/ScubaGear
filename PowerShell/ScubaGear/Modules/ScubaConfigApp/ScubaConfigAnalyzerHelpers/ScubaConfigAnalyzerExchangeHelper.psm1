<#
.SYNOPSIS
    Analyzer helper: Exchange Online / Security & Compliance token + direct REST data collection.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

function Connect-ScubaAnalyzerExchange {
    <#
    .SYNOPSIS
    Acquires an Exchange Online REST session (MSAL access token + Admin API endpoint) exactly
    like ScubaGear - NO ExchangeOnlineManagement module. App-only uses AppId + CertificateThumbprint;
    interactive uses ScubaGear's public client. Stores the token + endpoint on $syncHash for
    Get-ScAExchangeData. Call on the UI/sign-in thread (a Graph connection must already exist).
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ConnectCmdlet', Justification = 'Kept for schema compatibility; REST is used instead of a connect cmdlet.')]
    param(
        [string]$M365Environment = 'commercial',
        [string]$Organization,
        [string]$AppId,
        [string]$CertificateThumbprint,
        [string]$ConnectCmdlet = 'Connect-ExchangeOnline'
    )

    # Reuse ScubaGear's own REST + MSAL helpers so the auth/endpoint logic stays identical.
    Import-Module $syncHash.EXORestHelperPath  -Force -ErrorAction Stop
    Import-Module $syncHash.ConnectHelpersPath -Force -ErrorAction Stop

    # Tenant id + initial (onmicrosoft.com) domain for the endpoint / anchor mailbox, from the live
    # Graph session established in Phase A.
    $ctx = Get-MgContext
    $tenantId     = if ($ctx) { [string]$ctx.TenantId } else { $null }
    $tenantDomain = $Organization
    # If the organization parameter is not provided, fall back to the tenant domain from the Graph context.
    # This ensures that the Exchange Online connection uses the correct tenant context.
    try {
        $org = @((Invoke-MgGraphRequest -Method GET -Uri 'v1.0/organization' -OutputType PSObject).value)
        if (@($org).Count -gt 0) {
            if (-not $tenantId) { $tenantId = [string]$org[0].id }
            $initial = @($org[0].verifiedDomains | Where-Object { $_.isInitial })
            if (@($initial).Count -gt 0) { $tenantDomain = [string]$initial[0].name }
        }
    } catch { Write-ScubaAnalyzerLog  "Organization lookup for the EXO endpoint failed: $($_.Exception.Message)" -Level 'Warning' }
    # Ensure that we have both a tenant ID and a tenant domain before proceeding with the Exchange Online connection.
    if (-not $tenantId)     { throw "Cannot acquire an Exchange Online token: no Graph tenant context (connect to Graph first)." }
    if (-not $tenantDomain) { $tenantDomain = $Organization }

    # Acquire an access token for Exchange Online using either app-only certificate auth or delegated auth.
    $scope = Get-ExchangeOnlineScope -M365Environment $M365Environment
    if ($AppId -and $CertificateThumbprint) {
        # App-only certificate auth (non-interactive).
        $token = Get-MsalAccessToken -Scope $scope -CertificateThumbprint $CertificateThumbprint -AppID $AppId -Tenant $Organization -M365Environment $M365Environment
    } else {
        # ScubaGear's public client id for delegated EXO tokens.
        $token = Get-MsalAccessToken -Scope $scope -ClientId 'fb78d390-0c51-40cd-8e17-fdbfab77341b' -Tenant $tenantDomain -M365Environment $M365Environment
    }

    # Store the acquired access token and API endpoint in the shared hash for later use.
    $syncHash.EXOAccessToken = $token
    $syncHash.EXOApiEndpoint = Get-ExchangeOnlineApiEndpoint -TenantId $tenantId -TenantDomain $tenantDomain -M365Environment $M365Environment -AccessToken $token
    return $true
}

function Get-ScAExchangeData {
    <#
    .SYNOPSIS
    Runs an Exchange Online / EOP cmdlet (e.g. Get-RemoteDomain, Get-AntiPhishPolicy) via the
    Admin REST API using the token + endpoint from Connect-ScubaAnalyzerExchange - NO
    ExchangeOnlineManagement module. Throws so the caller can warn and fall back to manual review.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Organization', Justification = 'Kept for signature compatibility; the REST endpoint/token already carry tenant context.')]
    param(
        [Parameter(Mandatory)]$Fetch,
        [string]$Organization
    )

    # Ensure that the Exchange Online REST session is available before attempting to run the cmdlet.
    $cmdlet = [string]$Fetch.cmdlet
    if (-not $syncHash.EXOAccessToken -or -not $syncHash.EXOApiEndpoint) {
        throw "No Exchange Online REST session - Connect-ScubaAnalyzerExchange did not run or failed."
    }
    # Import the helper module for making REST calls to Exchange Online.
    Import-Module $syncHash.EXORestHelperPath -Force -ErrorAction Stop
    
    # Invoke the specified Exchange Online cmdlet via the REST API and return the results.
    return @(Invoke-EXORestMethod -CmdletName $cmdlet -ApiEndpoint $syncHash.EXOApiEndpoint -AccessToken $syncHash.EXOAccessToken)
}

