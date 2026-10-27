using module '..\ScubaConfig\ScubaConfig.psm1'

<#
Authentication flow and state diagram: /docs/MSAL-INTEGRATION.md

Public authentication client IDs are defined in ScubaConfigDefaults.json under AuthenticationClientIdHashtable.
Product                   Microsoft application                   Client ID
==========                ====================                    =========
aad                       Microsoft Graph PowerShell              14d82eec-204b-4c2f-b7e8-296a70dab67e
exo, securitysuite        Exchange Online PowerShell              fb78d390-0c51-40cd-8e17-fdbfab77341b
powerbi, powerplatform    Azure PowerShell                        1950a258-227b-4e31-a9cf-717495945fc2
sharepoint                SharePoint Online Management Shell      9bc3ab49-b65d-410a-85ad-de819febfddc
teams                     Teams PowerShell                        12128f48-ec9e-42f0-b203-ea49fb6af367

Access the mapping with [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable').
#>

# The MSAL session is the cross-module singleton created in ConnectHelpers.psm1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Cross-module singleton required for MSAL session sharing')]
param()
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'ConnectHelpers.psm1') -Function Connect-GraphHelper, Disconnect-ScubaGraph, Initialize-Msal, Get-MsalAccessToken, Invoke-ScubaGraphRequest, Get-ScubaGearContext, Get-M365EnvironmentByDomain

function Connect-Tenant {
    <#
   .Description
   This function uses the various PowerShell modules to establish
   a connection to an M365 Tenant associated with provided
   credentials
   .Functionality
   Internal
   .Notes
    The M365Environment default values are pulled from the ScubaConfig schema.
   #>
   [CmdletBinding(DefaultParameterSetName='Manual')]
   param (
   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(ParameterSetName = 'Manual')]
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_ -cin [ScubaConfig]::GetSupportedProducts() })]
   [string[]]
   $ProductNames,

   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(ParameterSetName = 'Manual')]
   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_ -cin [ScubaConfig]::GetSupportedEnvironments() })]
   [string]
   $M365Environment,

   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(Mandatory = $false)]
   [AllowNull()]
   [hashtable]
    $ServicePrincipalParams
   )
   $ClientIdHash = [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable')
   $AuthVerbose = @{}
   if ($VerbosePreference -eq 'Continue') { $AuthVerbose.Verbose = $true }
   Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable, Get-ScubaGearServiceEndpoint
   Import-Module -Name $PSScriptRoot/../Utility/ScubaLogging.psm1 -Function Write-ScubaLog
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/PowerPlatformRestHelper.psm1 -Function Get-PowerPlatformBaseUrl, Get-PowerPlatformScope
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/TeamsRestHelper.psm1 -Function Get-TeamsScope, Get-TeamsBaseUrl, Get-TeamsUnifiedScope, Get-TeamsUnifiedBaseUrl
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/SPORestHelper.psm1 -Function Get-SPOAdminUrl
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/PowerBIRestHelper.psm1 -Function Get-PowerBIBaseUrl, Get-PowerBIScope
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/EXORestHelper.psm1 -Function Get-ExchangeOnlineScope, Get-ExchangeOnlineApiEndpoint, Get-ComplianceScope, Get-ComplianceApiEndpoint

   # Prevent duplicate sign ins
   $EXOAuthRequired = $true
   $SPOAuthRequired = $true
   $AADAuthRequired = -not $Global:ScubaGearState.Session

   $ProdAuthFailed = @()

   # Track whether Power BI license was found
   $PBILicenseFound = $false
   $PBILicenseReason = ""

   # Download & load the MSAL libraries before the product loop. Let the user known up front if any errors.
   Initialize-Msal @AuthVerbose
   $DetectedM365Environment = $null

   # If interactive authentication, then discover the M365Environment automatically regardless if the user specified it or not.
   if (-not $ServicePrincipalParams.CertThumbprintParams) {
       # If the user has already connected to a tenant in this session, no need to do M365Environment discovery again.
       if ($Global:ScubaGearState.Session) {
           $M365Environment = $Global:ScubaGearState.Session.M365Environment
           $DetectedM365Environment = $M365Environment
           Write-Information "Previously discovered M365Environment: $M365Environment" -InformationAction Continue
       }
       # There is no existing session, so we need to discover the M365Environment interactively.
       else {
           # We ask for all the necessary scopes during discovery as the user signs in, so that we don't have to prompt the user for consent in a separate tab.
           $GraphScopes = if ($ProductNames -contains 'aad') { Get-ScubaGearEntraMinimumPermissions } else { @('Organization.Read.All') }
            # Discover the environment and establish the Graph session in one operation.
           Connect-GraphHelper @AuthVerbose -Discovery -Scopes $GraphScopes
           $M365Environment = $Global:ScubaGearState.Session.M365Environment
           $DetectedM365Environment = $M365Environment
           $AADAuthRequired = $false
           Write-Information "Automatically discovered M365Environment: $M365Environment" -InformationAction Continue
       }
   }

   # Resolve tenant metadata once and share it across products during this connection.
   $TenantId = $null
   $TenantName = $null
   $InitialDomainPrefix = $null

   # Token data for REST-based products (populated during connection)
   $TokenData = @{
       SPOAccessToken     = $null
       SPOAdminUrl        = $null
       PPAccessToken      = $null
       PPBaseUrl          = $null
       PBIAccessToken     = $null
       PBIBaseUrl         = $null
       EXOAccessToken     = $null
       EXOApiEndpoint     = $null
       ComplianceAccessToken = $null
       ComplianceApiEndpoint = $null
       TeamsAccessToken   = $null
       TeamsBaseUrl     = $null
       TeamsUnifiedAccessToken   = $null
       TeamsUnifiedBaseUrl     = $null
   }
   $N = 0
   $Len = $ProductNames.Length

   foreach ($Product in $ProductNames) {
       $N += 1
       $Percent = $N*100/$Len
       # securitysuite technically isn't a "product" so say "Authenticating to defender" for it
       # rather than "Authenticating to securitysuite"
       $ProductName = if ($Product -ne "securitysuite") { $Product } else { "defender" }
       $ProgressParams = @{
           'Activity' = "Authenticating to each Product";
           'Status' = "Authenticating to $($ProductName); $($N) of $($Len) Products authenticated to.";
           'PercentComplete' = $Percent;
       }
       Write-Progress @ProgressParams
       try {
           switch ($Product) {
               "aad" {
                   $GraphScopes = Get-ScubaGearEntraMinimumPermissions
                   if ($AADAuthRequired) {
                       $GraphParams = @{
                           'M365Environment' = $M365Environment;
                           'Scopes' = $GraphScopes;
                       }
                       if ($ServicePrincipalParams) {
                           $GraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @AuthVerbose @GraphParams
                   }
                   elseif (-not $Global:ScubaGearState.Session.TokenParameters.CertificateThumbprint) {
                       # A previous scan without aad may have requested only Organization.Read.All.
                       $MissingScopes = @($GraphScopes | Where-Object { $_ -notin $Global:ScubaGearState.Session.TokenParameters.Scope })
                       if ($MissingScopes.Count -gt 0) {
                           $TokenParameters = $Global:ScubaGearState.Session.TokenParameters.Clone()
                           $TokenParameters.Scope = @(@($TokenParameters.Scope) + $GraphScopes | Sort-Object -Unique)
                           $null = Get-MsalAccessToken @AuthVerbose @TokenParameters
                           $Global:ScubaGearState.Session.TokenParameters = $TokenParameters
                       }
                   }
                   $AADAuthRequired = $false
               }
               {($_ -eq "exo") -or ($_ -eq "securitysuite")} {
                   if ($EXOAuthRequired) {
                       if ($AADAuthRequired) {
                           $LimitedGraphParams = @{
                               'M365Environment' = $M365Environment;
                           }
                           if ($ServicePrincipalParams) {
                               $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                           }
                           Connect-GraphHelper @AuthVerbose @LimitedGraphParams
                           $AADAuthRequired = $false
                       }

                       # Resolve tenant info if not already cached
                       if ([string]::IsNullOrEmpty($TenantName)) {
                           $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                           $TenantId = $OrgDetails.Id
                           $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                           $TenantName = $InitialDomain.Name
                           $InitialDomainPrefix = $TenantName.split(".")[0]
                       }

                       # Acquire Exchange Online access token
                       $EXOScope = Get-ExchangeOnlineScope -M365Environment $M365Environment

                       if ($ServicePrincipalParams.CertThumbprintParams) {
                           $TokenData.EXOAccessToken = Get-MsalAccessToken @AuthVerbose `
                               -Scope $EXOScope `
                               -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                               -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                               -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                               -M365Environment $M365Environment
                       }
                       else {
                           $EXOClientId = $ClientIdHash.exo
                           $EXOAuthParams = @{
                               Scope = $EXOScope
                               ClientId = $EXOClientId
                               Tenant = $TenantName
                               M365Environment = $M365Environment
                           }
                           $TokenData.EXOAccessToken = Get-MsalAccessToken @AuthVerbose @EXOAuthParams
                       }

                       # Resolve the EXO API endpoint (handles redirects)
                       $TokenData.EXOApiEndpoint = Get-ExchangeOnlineApiEndpoint `
                           -TenantId $TenantId `
                           -TenantDomain $TenantName `
                           -M365Environment $M365Environment `
                           -AccessToken $TokenData.EXOAccessToken

                       Write-Verbose "Exchange Online token and endpoint acquired successfully"

                       # Acquire Security & Compliance token and resolve the
                       # tenant-specific regional compliance endpoint for all environments.
                       $ComplianceScope = Get-ComplianceScope -M365Environment $M365Environment
                       try {
                           if ($ServicePrincipalParams.CertThumbprintParams) {
                               $TokenData.ComplianceAccessToken = Get-MsalAccessToken @AuthVerbose `
                                   -Scope $ComplianceScope `
                                   -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                                   -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                                   -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                                   -M365Environment $M365Environment
                           }
                           else {
                               $ComplianceAuthParams = @{
                                   Scope = $ComplianceScope
                                   ClientId = $ClientIdHash.securitysuite
                                   Tenant = $TenantName
                                   M365Environment = $M365Environment
                               }
                               $TokenData.ComplianceAccessToken = Get-MsalAccessToken @AuthVerbose @ComplianceAuthParams
                           }
                           $TokenData.ComplianceApiEndpoint = Get-ComplianceApiEndpoint `
                               -TenantId $TenantId `
                               -TenantDomain $TenantName `
                               -M365Environment $M365Environment `
                               -AccessToken $TokenData.ComplianceAccessToken
                           Write-Verbose "Compliance token acquired. Endpoint: $($TokenData.ComplianceApiEndpoint)"
                       }
                       catch {
                           Write-Warning "Failed to acquire compliance token: $($_.Exception.Message). Compliance cmdlets will use EXO endpoint."
                       }

                       $EXOAuthRequired = $false
                   }
               }
               "powerplatform" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @AuthVerbose @LimitedGraphParams
                       $AADAuthRequired = $false
                   }

                   # Acquire Power Platform access token
                   $PPScope = Get-PowerPlatformScope -M365Environment $M365Environment
                   $TokenData.PPBaseUrl = Get-PowerPlatformBaseUrl -M365Environment $M365Environment

                   if ($ServicePrincipalParams.CertThumbprintParams) {
                       $TokenData.PPAccessToken = Get-MsalAccessToken @AuthVerbose `
                           -Scope $PPScope `
                           -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                           -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                           -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                           -M365Environment $M365Environment
                   }
                   else {
                       # Resolve tenant name if not already cached from a previous product
                       if ([string]::IsNullOrEmpty($TenantName)) {
                           $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                           $TenantId = $OrgDetails.Id
                           $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                           $TenantName = $InitialDomain.Name
                           $InitialDomainPrefix = $TenantName.split(".")[0]
                       }

                       # Azure PowerShell well-known client ID
                       $PPClientId = $ClientIdHash.powerplatform
                       $PPAuthParams = @{
                           Scope = $PPScope
                           ClientId = $PPClientId
                           Tenant = $TenantName
                           M365Environment = $M365Environment
                       }
                       $TokenData.PPAccessToken = Get-MsalAccessToken @AuthVerbose @PPAuthParams
                   }
                   Write-Verbose "Power Platform token acquired successfully"
               }
               "sharepoint" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams }
                       }
                       Connect-GraphHelper @AuthVerbose @LimitedGraphParams
                       $AADAuthRequired = $false
                   }
                   if ($SPOAuthRequired) {
                       # Resolve tenant info if not already cached from a previous product
                       if ([string]::IsNullOrEmpty($TenantName)) {
                           $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                           $TenantId = $OrgDetails.Id
                           $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                           $TenantName = $InitialDomain.Name
                           $InitialDomainPrefix = $TenantName.split(".")[0]
                       }

                       $TokenData.SPOAdminUrl = Get-ScubaGearServiceEndpoint -Product sharepoint -Environment $M365Environment -Domain $InitialDomainPrefix
                       $SPOScope = "$($TokenData.SPOAdminUrl)/.default"

                       if ($ServicePrincipalParams.CertThumbprintParams) {
                           $TokenData.SPOAccessToken = Get-MsalAccessToken @AuthVerbose `
                               -Scope $SPOScope `
                               -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                               -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                               -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                               -M365Environment $M365Environment
                       }
                       else {
                           # SharePoint Online Management Shell app ID
                           $SPOClientId = $ClientIdHash.sharepoint
                           $SPOAuthParams = @{
                               Scope = $SPOScope
                               ClientId = $SPOClientId
                               Tenant = $TenantName
                               M365Environment = $M365Environment
                           }
                           $TokenData.SPOAccessToken = Get-MsalAccessToken @AuthVerbose @SPOAuthParams
                       }
                       Write-Verbose "SharePoint token acquired successfully"
                       $SPOAuthRequired = $false
                   }
               }
               "powerbi" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                           'Scopes' = @("Organization.Read.All");
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @AuthVerbose @LimitedGraphParams
                       $AADAuthRequired = $false
                   }

                   # Check for Power BI license before attempting token acquisition.
                   # This prevents triggering a second consent/browser window for the
                   # Power BI API scope when the tenant has no PBI license at all.
                   $TenantHasPBILicense = $false
                   $SubscribedSku = (Invoke-GraphDirectly -Commandlet Get-MgBetaSubscribedSku -M365Environment $M365Environment).Value
                   $ServicePlans = $SubscribedSku.ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success"
                   if ($ServicePlans) {
                       $PBIServicePlans = $ServicePlans | Where-Object -Property ServicePlanName -Match -Value "(POWER_BI|BI_AZURE_P_?[0-9]|PBI_PREMIUM|FABRIC)"
                       if ($PBIServicePlans) {
                           $TenantHasPBILicense = $true
                           # Get the unique names of the detected Power BI service plans.
                           $PlanNames = ($PBIServicePlans | ForEach-Object { $_.ServicePlanName } | Select-Object -Unique) -join ", "

                           # Log to debug log only (kept off the console to reduce noise)
                           Write-ScubaLog -Message "Power BI license found: $PlanNames" -Level "Info" -Source "Connect-Tenant"
                       }
                   }

                   if (-not $TenantHasPBILicense) {
                       $PBILicenseReason = "No Power BI or Fabric license found in the tenant."
                       # Shown in the report, and logged to the debug log instead of the console
                       Write-ScubaLog -Message $PBILicenseReason -Level "Info" -Source "Connect-Tenant"
                       # Mark license as not found to avoid attempting Power BI API calls later, which would trigger consent/sign-in without a license.
                       $PBILicenseFound = $false
                   }
                   else {
                       # For interactive mode, also check that the current user has a PBI/Fabric license assigned.
                       # The Power BI Admin API requires the calling user to have a license even for Global Admin.
                       if (-not $ServicePrincipalParams.CertThumbprintParams) {
                           $UserLicenseResponse = Invoke-GraphDirectly -Uri "/v1.0/me/licenseDetails" -Method GET
                           # Collect every successfully provisioned service plan assigned to the current user.
                           $UserPlans = $UserLicenseResponse.value |
                               Where-Object { $null -ne $_.servicePlans } |
                               ForEach-Object { $_.servicePlans } |
                               Where-Object { $_.provisioningStatus -eq "Success" }

                           # Filter the user's service plans to include only those related to Power BI or Fabric.
                           $UserPBIPlans = @($UserPlans |Where-Object { $_.servicePlanName -match "(POWER_BI|BI_AZURE_P_?[0-9]|PBI_PREMIUM|FABRIC)" })
                           if ($UserPBIPlans.Count -eq 0) {
                               $PBILicenseFound = $false

                               # Shown in the report, and logged to the debug log instead of the console
                               $PBILicenseReason = "Current user does not have a Power BI or Fabric license assigned. To include Power BI, assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user."
                               Write-ScubaLog -Message $PBILicenseReason -Level "Info" -Source "Connect-Tenant"
                           }
                           else {
                               $PBILicenseFound = $true
                               # Get the unique names of the user's Power BI/Fabric service plans.
                               $UserPlanNames = ($UserPBIPlans | ForEach-Object { $_.servicePlanName } | Select-Object -Unique) -join ", "

                               # Log the user's Power BI/Fabric license status to the debug log only.
                               # PBILicenseReason stays empty here because it is only set when the license check fails.
                               Write-ScubaLog -Message "User Power BI/Fabric license found: $UserPlanNames" -Level "Info" -Source "Connect-Tenant"
                           }
                       }
                       # Skip this check for service principal auth (SPs use tenant setting + security group).
                       else {
                           $PBILicenseFound = $true
                       }

                       if ($PBILicenseFound) {
                           # Acquire Power BI access token
                           $PBIScope = Get-PowerBIScope -M365Environment $M365Environment
                           $TokenData.PBIBaseUrl = Get-PowerBIBaseUrl -M365Environment $M365Environment
                           if ($ServicePrincipalParams.CertThumbprintParams) {
                               $TokenData.PBIAccessToken = Get-MsalAccessToken @AuthVerbose `
                                   -Scope $PBIScope `
                                   -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                                   -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                                   -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                                   -M365Environment $M365Environment
                           }
                           else {
                               # Resolve tenant name if not already cached from a previous product
                               if ([string]::IsNullOrEmpty($TenantName)) {
                                   $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                                   $TenantId = $OrgDetails.Id
                                   $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                                   $TenantName = $InitialDomain.Name
                                   $InitialDomainPrefix = $TenantName.split(".")[0]
                               }
                               # Same ClientId as PowerPlatform - MSAL cache and SSO enable silent acquisition
                               # if PowerPlatform already signed in interactively this session.
                               $PBIClientId = $ClientIdHash.powerbi
                               $PBIAuthParams = @{
                                   Scope = $PBIScope
                                   ClientId = $PBIClientId
                                   Tenant = $TenantName
                                   M365Environment = $M365Environment
                               }
                               $TokenData.PBIAccessToken = Get-MsalAccessToken @AuthVerbose @PBIAuthParams
                           }
                           Write-Verbose "Power BI token acquired successfully"
                       }
                   }
               }
               "teams" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @AuthVerbose @LimitedGraphParams
                       $AADAuthRequired = $false
                   }

                    # Get access tokens for Teams Admin API and Teams Unified settings API
                    # The Teams Unified settings API is used for some operations that are not available in the standard Teams Admin API
                    $TeamsScope = Get-TeamsScope -M365Environment $M365Environment
                    $TokenData.TeamsBaseUrl = Get-TeamsBaseUrl -M365Environment $M365Environment

                    # Teams unified settings API is only available in environments that are not gcc high and dod.
                    if ($M365Environment -notin @('gcchigh', 'dod')) {
                        $TeamsUnifiedScope = Get-TeamsUnifiedScope -M365Environment $M365Environment
                        $TokenData.TeamsUnifiedBaseUrl = Get-TeamsUnifiedBaseUrl -M365Environment $M365Environment
                    }
                    else {
                        # Set auth return values to empty strings since API is not available
                        $TokenData.TeamsUnifiedBaseUrl = ""
                        $TokenData.TeamsUnifiedAccessToken = ""
                    }

                    # MS Teams Powershell Cmdlets well-knodwn client ID used when authenticating interactively
                    $TeamsClientId = $ClientIdHash.teams

                    if ($ServicePrincipalParams.CertThumbprintParams) {
                        # Get the token for the Teams admin API, which is used for most Teams operations
                        $TokenData.TeamsAccessToken = Get-MsalAccessToken @AuthVerbose `
                            -Scope $TeamsScope `
                            -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                            -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                            -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                            -M365Environment $M365Environment

                        # Set auth return values to empty strings since Teams unified setttings API is only available for interactive auth flows.
                        $TokenData.TeamsUnifiedBaseUrl = ""
                        $TokenData.TeamsUnifiedAccessToken = ""
                    }
                    else {
                        # Resolve tenant domain name if not already cached from a previous product
                        if ([string]::IsNullOrEmpty($TenantName)) {
                            $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                            $TenantId = $OrgDetails.Id
                            $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                            $TenantName = $InitialDomain.Name
                            $InitialDomainPrefix = $TenantName.split(".")[0]
                        }

                        # Get the token for the Teams admin API, which is used for most Teams operations
                        $TokenData.TeamsAccessToken = Get-MsalAccessToken @AuthVerbose `
                            -Scope $TeamsScope `
                            -ClientId $TeamsClientId `
                            -Tenant $TenantName `
                            -M365Environment $M365Environment

                        # Teams unified settings API is only available in environments that are not gcc high and dod.
                        if ($M365Environment -notin @('gcchigh', 'dod')) {
                            # Get the token for the Teams Unified settings API, which is used for some operations that are not available in the standard Teams Admin API
                            $TokenData.TeamsUnifiedAccessToken = Get-MsalAccessToken @AuthVerbose `
                                -Scope $TeamsUnifiedScope `
                                -ClientId $TeamsClientId `
                                -Tenant $TenantName `
                                -M365Environment $M365Environment
                        }
                   }
               }
               default {
                   throw "Invalid ProductName argument"
               }
           }
       }
       catch {
           $ErrorDetails = @{
               Product = $Product
               ErrorMessage = $_.Exception.Message
               ErrorType = $_.Exception.GetType().FullName
               ScriptStackTrace = $_.ScriptStackTrace
               TargetObject = if ($_.TargetObject) { $_.TargetObject.ToString() } else { "N/A" }
           }

           # Log detailed error information for troubleshooting
           Write-ScubaLog -Message "Authentication failed for product: $Product" -Level "Error" -Source "ConnectTenant" -Data $ErrorDetails

           Write-Warning "Error establishing a connection with $($Product): $($_.Exception.Message)`n$($_.ScriptStackTrace)"
           $ProdAuthFailed += $Product
           Write-Warning "$($Product) will be omitted from the output because of failed authentication"
       }
   }
   Write-Progress -Activity "Authenticating to each service" -Status "Ready" -Completed
   @{
       DetectedM365Environment = $DetectedM365Environment
       ProdAuthFailed   = $ProdAuthFailed
       PBILicenseFound  = $PBILicenseFound
       PBILicenseReason = $PBILicenseReason
       SPOAccessToken   = $TokenData.SPOAccessToken
       SPOAdminUrl      = $TokenData.SPOAdminUrl
       PPAccessToken    = $TokenData.PPAccessToken
       PPBaseUrl        = $TokenData.PPBaseUrl
       PBIAccessToken   = $TokenData.PBIAccessToken
       PBIBaseUrl       = $TokenData.PBIBaseUrl
       EXOAccessToken   = $TokenData.EXOAccessToken
       ComplianceAccessToken = $TokenData.ComplianceAccessToken
       ComplianceApiEndpoint = $TokenData.ComplianceApiEndpoint
       EXOApiEndpoint   = $TokenData.EXOApiEndpoint
       TeamsAccessToken = $TokenData.TeamsAccessToken
       TeamsBaseUrl = $TokenData.TeamsBaseUrl
       TeamsUnifiedAccessToken   = $TokenData.TeamsUnifiedAccessToken
       TeamsUnifiedBaseUrl     = $TokenData.TeamsUnifiedBaseUrl
   }
}

function Disconnect-SCuBATenant {
   <#
   .SYNOPSIS
       Disconnect all active M365 connection sessions made by ScubaGear
   .DESCRIPTION
       Forces disconnect of all active authentication sessions associated with an M365 tenant.
       Call this when you want to switch ScubaGear to audit a different tenant.
   .EXAMPLE
   Disconnect-SCuBATenant
   .Functionality
   Public
   #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]
        $ProductNames
    )

    if ($PSBoundParameters.ContainsKey('ProductNames')) {
        Write-Warning "-ProductNames is deprecated and ignored; Disconnect-SCuBATenant now always disconnects the full tenant session."
    }

    try {
        Write-Information "Disconnecting from tenant..." -InformationAction Continue
        Disconnect-ScubaGraph
        Write-Information "Disconnect Completed!" -InformationAction Continue
    } catch {
        Write-Warning "Could not disconnect from tenant`n: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
    }
}

function Get-ServicePrincipalParams {
    <#
    .Description
    Returns a valid a hastable of parameters for authentication via
    Service Principal. Throws an error if there are none.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    $ScubaConfig
    )

    $ServicePrincipalParams = @{}

    $CheckThumbprintParams = ($ScubaConfig.CertificateThumbprint) `
    -and ($ScubaConfig.AppID) -and ($ScubaConfig.Organization)

    if ($CheckThumbprintParams) {
        $CertThumbprintParams = @{
            CertificateThumbprint = $ScubaConfig.CertificateThumbprint;
            AppID = $ScubaConfig.AppID;
            Organization = $ScubaConfig.Organization;
        }
        $ServicePrincipalParams += @{CertThumbprintParams = $CertThumbprintParams}
    }
    else {
        throw "When authenticating with Service Principal authentication, the following command line parameters must be provided: -AppID, -CertificateThumbprint and -Organization."
    }
    $ServicePrincipalParams
}

Export-ModuleMember -Function @(
    'Connect-Tenant',
    'Disconnect-SCuBATenant',
    'Get-ServicePrincipalParams',
    'Get-M365EnvironmentByDomain',
    'Get-ScubaGearContext'
)
