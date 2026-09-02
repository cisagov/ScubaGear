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

    ################### If we receive a very specific error from Connect-MgGraph, we will retry with the GCC High environment.
    try {
        $null = Connect-MgGraph @GraphParams
    }
    catch {
        $ErrorText = $_.Exception.Message

        $IsWrongCloudError =
            $ErrorText -match "AADSTS900384" -and
            $ErrorText -match "determine the corresponding service endpoint"

        if (-not $IsWrongCloudError) {
            throw
        }

        Write-Information "Detected a login to a tenant that is not Commercial or GCC. Retrying with GCC High environment login page..." -InformationAction Continue
        $GraphParams += @{'Environment' = "USGov"; }
        $null = Connect-MgGraph @GraphParams
    }
        Write-Information "Detected a login to a tenant that is not Commercial or GCC. Retrying with GCC High environment login page..." -InformationAction Continue
        $GraphParams += @{'Environment' = "USGov"; }
        $null = Connect-MgGraph @GraphParams
    }
    ###################
}

function Initialize-Msal {
    <#
    .SYNOPSIS
        Ensures the MSAL assembly is loaded and types are resolvable.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    # ------------------------------------------------------------------
    # 1. See if the MSAL types are already resolvable
    # ------------------------------------------------------------------
    try {
        # If the MSAL types are already loaded, this will succeed and we can skip the rest of this function.
        $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
        return
    }
    catch {
        Write-Information "MSAL types not yet resolvable so ScubaGear is loading them..." -InformationAction Continue
    }

    # ------------------------------------------------------------------
    # 2. Load the MSAL types so that they are resolvable
    # ------------------------------------------------------------------

    # We have a different solution for PowerShell 5.1 vs PowerShell 7 because the same solution didn't work for both based on testing.
    $RuntimeVersion = if ($PSVersionTable.PSEdition -eq 'Core') { 'Core' } else { 'Desktop' }

    # PowerShell 5.1 solution
    if ($RuntimeVersion -eq 'Desktop') {
        # Call Connect-MgGraph with a bogus thumbprint purely to force MSAL to load.
        # We expect this to fail we just want the side effect of loading Microsoft.Identity.Client.dll.
        try {
            Connect-MgGraph `
                -CertificateThumbprint '2A0268B04B9F22EFA77A0EFF01930ADE279AC072' `
                -ClientId 'ad1cb53b92084abeb99c3acf35c91c2a' `
                -TenantId 'bogus.onmicrosoft.com' `
                -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -like '*was not found in certificate store*') {
                # Do nothing - this is the expected error, and it means MSAL was loaded successfully.
            }
            # Some unrelated error occurred so we can't be sure MSAL was loaded. Rethrow the error so the user can see it.
            else {
                throw
            }
        }
    }
    # PowerShell 7 solution
    else {
        # If Graph auth module is not already loaded, load it so we can find the MSAL assembly.
        $GraphModule = Get-Module Microsoft.Graph.Authentication
        if (-not $GraphModule) {
            Import-Module Microsoft.Graph.Authentication
            $GraphModule = Get-Module Microsoft.Graph.Authentication
        }

        $ModulePath = $GraphModule.Path | Split-Path
        # $MsalDll = Get-ChildItem -Path $ModulePath -Recurse -Filter "Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
        $MsalDll = Get-ChildItem -Path $ModulePath -Recurse -Filter "Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue |
                Where-Object { $_.Directory.Name -eq $RuntimeVersion } |
                Select-Object -First 1

        if (-not $MsalDll) {
            throw "Microsoft.Identity.Client.dll not found in the Microsoft.Graph.Authentication module directory."
        }

        Write-Information "Loading MSAL from path: $($MsalDll.FullName)" -InformationAction Continue
        Add-Type -Path $MsalDll.FullName
    }

    # ------------------------------------------------------------------
    # 3. Verify the type is now loaded and resolvable
    # ------------------------------------------------------------------

    try {
        $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
        # It is resolvable so we succeeded.
        Write-Information "Successfully loaded MSAL types." -InformationAction Continue
        return
    }
    catch {
        Write-Warning "MSAL still not resolvable after going through loader code!"
        throw
    }
}

function Get-MsalAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token via MSAL using certificate or interactive auth.
        Reuses cached MSAL app instances and attempts silent token acquisition before
        prompting interactively, minimizing the number of browser popups per session.
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

    if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
        $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        if (-not $Certificate) {
            $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        }
        if (-not $Certificate) {
            throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
        }
    }

    # Cache MSAL app instances by key so token cache persists across calls.
    # This enables AcquireTokenSilent to succeed for subsequent scope requests
    # after the first interactive sign-in, reducing browser popups to one.
    if (-not $Script:MsalAppCache) {
        $Script:MsalAppCache = @{}
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
                $CacheKey = "SP:$AppID|$Authority"
                if (-not $Script:MsalAppCache.ContainsKey($CacheKey)) {
                    $Script:MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                        WithCertificate($Certificate).
                        WithAuthority($Authority).
                        Build()
                }
                $MsalApp = $Script:MsalAppCache[$CacheKey]
                $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@($Scope)).ExecuteAsync().GetAwaiter().GetResult()
            }
            else {
                $RedirectUri = "http://localhost"
                $CacheKey = "PUB:$ClientId|$Authority"
                if (-not $Script:MsalAppCache.ContainsKey($CacheKey)) {
                    $Script:MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                        WithAuthority($Authority).
                        WithRedirectUri($RedirectUri).
                        Build()
                }
                $MsalApp = $Script:MsalAppCache[$CacheKey]

                # Try silent acquisition first using cached accounts
                $TokenResult = $null
                try {
                    $Accounts = $MsalApp.GetAccountsAsync().GetAwaiter().GetResult()
                    if ($Accounts -and $Accounts.Count -gt 0) {
                        $TokenResult = $MsalApp.AcquireTokenSilent([string[]]@($Scope), $Accounts[0]).
                            ExecuteAsync().GetAwaiter().GetResult()
                    }
                }
                catch {
                    # Silent failed (no cached token for this scope) — fall through to interactive
                    $TokenResult = $null
                }

                if (-not $TokenResult) {
                    $TokenResult = $MsalApp.AcquireTokenInteractive([string[]]@($Scope)).
                        WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).
                        WithUseEmbeddedWebView($true).
                        ExecuteAsync().GetAwaiter().GetResult()
                }
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
    'Initialize-Msal',
    'Get-MsalAccessToken'
)
