function Connect-Tenant {
    <#
   .Description
   This function uses the various PowerShell modules to establish
   a connection to an M365 Tenant associated with provided
   credentials
   .Functionality
   Internal
   #>
   [CmdletBinding(DefaultParameterSetName='Manual')]
   param (
   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(ParameterSetName = 'Manual')]
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [ValidateSet("teams", "exo", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", IgnoreCase = $false)]
   [string[]]
   $ProductNames,

   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(ParameterSetName = 'Manual')]
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
   [string]
   $M365Environment,

   [Parameter(ParameterSetName = 'Auto')]
   [Parameter(Mandatory = $false)]
   [AllowNull()]
   [hashtable]
   $ServicePrincipalParams
   )
   Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "ConnectHelpers.psm1")
   Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable
   Import-Module -Name $PSScriptRoot/../Utility/ScubaLogging.psm1 -Function Write-ScubaLog
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/PowerPlatformRestHelper.psm1 -Function Get-PowerPlatformBaseUrl, Get-PowerPlatformScope
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/SPORestHelper.psm1 -Function Get-SPOAdminUrl
   Import-Module -Name $PSScriptRoot/../Providers/ProviderHelpers/PowerBIRestHelper.psm1 -Function Get-PowerBIBaseUrl, Get-PowerBIScope

   # Prevent duplicate sign ins
   $EXOAuthRequired = $true
   $SPOAuthRequired = $true
   $AADAuthRequired = $true

   $ProdAuthFailed = @()

   # Track whether Power BI license was found
   $PBILicenseFound = $false
   $PBILicenseReason = ""

   # Tenant name, domain prefix, and login hint resolved lazily and shared across PowerPlatform, PowerBI, and SharePoint
   $TenantName = $null
   $InitialDomainPrefix = $null
   # UPN captured after first successful Connect-GraphHelper; enables SSO (prompt=none) for PP, PBI, and SPO
   # by reusing the AAD browser session already established by Connect-MgGraph.
   $LoginHint = $null

   # Token data for REST-based products (populated during connection)
   $TokenData = @{
       SPOAccessToken  = $null
       SPOAdminUrl     = $null
       PPAccessToken   = $null
       PPBaseUrl       = $null
       PBIAccessToken  = $null
       PBIBaseUrl      = $null
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

                   $GraphParams = @{
                       'M365Environment' = $M365Environment;
                       'Scopes' = $GraphScopes;
                   }
                   if($ServicePrincipalParams) {
                    $GraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                   }
                   Connect-GraphHelper @GraphParams
                   $AADAuthRequired = $false
                   if (-not $LoginHint) {
                       $LoginHint = (Get-MgContext -ErrorAction SilentlyContinue).Account
                   }
               }
               {($_ -eq "exo") -or ($_ -eq "securitysuite")} {
                   if ($EXOAuthRequired) {
                       $EXOHelperParams = @{
                           M365Environment = $M365Environment;
                       }
                       if ($ServicePrincipalParams) {
                           $EXOHelperParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Write-Verbose "For the Security Suite baseline, Defender will require a sign in every single run regardless of what the LogIn parameter is set"
                       Connect-EXOHelper @EXOHelperParams
                       $EXOAuthRequired = $false
                   }
               }
               "powerplatform" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                           'ErrorAction' = 'Stop';
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @LimitedGraphParams
                       $AADAuthRequired = $false
                       if (-not $LoginHint) {
                           $LoginHint = (Get-MgContext -ErrorAction SilentlyContinue).Account
                       }
                   }

                   # Acquire Power Platform access token
                   $PPScope = Get-PowerPlatformScope -M365Environment $M365Environment
                   $TokenData.PPBaseUrl = Get-PowerPlatformBaseUrl -M365Environment $M365Environment

                   if ($ServicePrincipalParams.CertThumbprintParams) {
                       $TokenData.PPAccessToken = Get-MsalAccessToken `
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
                           $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                           $TenantName = $InitialDomain.Name
                           $InitialDomainPrefix = $TenantName.split(".")[0]
                       }

                       # Azure PowerShell well-known client ID
                       $PPClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
                       $TokenData.PPAccessToken = Get-MsalAccessToken `
                           -Scope $PPScope `
                           -ClientId $PPClientId `
                           -Tenant $TenantName `
                           -M365Environment $M365Environment `
                           -LoginHint $LoginHint
                   }
                   Write-Verbose "Power Platform token acquired successfully"
               }
               "powerbi" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                           'ErrorAction' = 'Stop';
                           'Scopes' = @("Organization.Read.All");
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Connect-GraphHelper @LimitedGraphParams
                       $AADAuthRequired = $false
                       if (-not $LoginHint) {
                           $LoginHint = (Get-MgContext -ErrorAction SilentlyContinue).Account
                       }
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
                            $PlanNames = ($PBIServicePlans | ForEach-Object { $_.ServicePlanName } | Select-Object -Unique) -join ", "
                            Write-Information "Power BI license found: $PlanNames" -InformationAction Continue
                        }
                  }

                   if (-not $TenantHasPBILicense) {
                       Write-Warning "No Power BI or Fabric license found in the tenant."
                       $PBILicenseFound = $false
                       $PBILicenseReason = "No Power BI or Fabric license found in the tenant."
                   }
                   else {
                       # For interactive mode, also check that the current user has a PBI/Fabric license assigned.
                       # The Power BI Admin API requires the calling user to have a license even for Global Admin.
                       if (-not $ServicePrincipalParams.CertThumbprintParams) {
                            $UserLicenseResponse = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/me/licenseDetails" -ErrorAction Stop
                            $UserPlans = $UserLicenseResponse.value |
                                Where-Object { $null -ne $_.servicePlans } |
                                ForEach-Object { $_.servicePlans } |
                                Where-Object { $_.provisioningStatus -eq "Success" }
                            $UserPBIPlans = @($UserPlans |Where-Object { $_.servicePlanName -match "(POWER_BI|BI_AZURE_P_?[0-9]|PBI_PREMIUM|FABRIC)" })
                            if ($UserPBIPlans.Count -eq 0) {
                                Write-Warning "Current user does not have a Power BI or Fabric license assigned. To include Power BI, assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user."
                                $PBILicenseFound = $false
                                $PBILicenseReason = "Current user does not have a Power BI or Fabric license assigned. Assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user."
                            }
                            else {
                                $PBILicenseFound = $true
                                $UserPlanNames = ($UserPBIPlans | ForEach-Object { $_.servicePlanName } | Select-Object -Unique) -join ", "
                                Write-Information "User Power BI/Fabric license found: $UserPlanNames" -InformationAction Continue
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
                                $TokenData.PBIAccessToken = Get-MsalAccessToken `
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
                                    $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                                    $TenantName = $InitialDomain.Name
                                    $InitialDomainPrefix = $TenantName.split(".")[0]
                                }
                                # Same ClientId as PowerPlatform — MSAL cache and SSO enable silent acquisition
                                # if PowerPlatform already signed in interactively this session.
                                $PBIClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
                                $TokenData.PBIAccessToken = Get-MsalAccessToken `
                                    -Scope $PBIScope `
                                    -ClientId $PBIClientId `
                                    -Tenant $TenantName `
                                    -M365Environment $M365Environment `
                                    -LoginHint $LoginHint
                            }
                            Write-Verbose "Power BI token acquired successfully"
                       }
                   }
               }
               "sharepoint" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'M365Environment' = $M365Environment;
                           'ErrorAction' = 'Stop';
                       }
                       if ($ServicePrincipalParams) {
                           $LimitedGraphParams += @{ServicePrincipalParams = $ServicePrincipalParams }
                       }
                       Connect-GraphHelper @LimitedGraphParams
                       $AADAuthRequired = $false
                       if (-not $LoginHint) {
                           $LoginHint = (Get-MgContext -ErrorAction SilentlyContinue).Account
                       }
                   }
                   if ($SPOAuthRequired) {
                       # Resolve tenant info if not already cached from a previous product
                       if ([string]::IsNullOrEmpty($TenantName)) {
                           $OrgDetails = (Invoke-GraphDirectly -Commandlet Get-MgBetaOrganization -M365Environment $M365Environment).Value
                           $InitialDomain = $OrgDetails.VerifiedDomains | Where-Object { $_.isInitial }
                           $TenantName = $InitialDomain.Name
                           $InitialDomainPrefix = $TenantName.split(".")[0]
                       }

                       $TokenData.SPOAdminUrl = Get-ScubaGearPermissions -Product sharepoint -OutAs endpoint -Environment $M365Environment -Domain $InitialDomainPrefix
                       $SPOScope = "$($TokenData.SPOAdminUrl)/.default"

                       if ($ServicePrincipalParams.CertThumbprintParams) {
                           $TokenData.SPOAccessToken = Get-MsalAccessToken `
                               -Scope $SPOScope `
                               -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                               -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                               -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                               -M365Environment $M365Environment
                       }
                       else {
                           # SharePoint Online Management Shell app ID
                           $SPOClientId = "9bc3ab49-b65d-410a-85ad-de819febfddc"
                           $TokenData.SPOAccessToken = Get-MsalAccessToken `
                               -Scope $SPOScope `
                               -ClientId $SPOClientId `
                               -Tenant $TenantName `
                               -M365Environment $M365Environment `
                               -LoginHint $LoginHint
                       }
                       Write-Verbose "SharePoint token acquired successfully"
                       $SPOAuthRequired = $false
                   }
               }
               "teams" {
                   $TeamsParams = @{'ErrorAction'= 'Stop'}
                   if ($ServicePrincipalParams.CertThumbprintParams) {
                       $TeamsConnectToTenant = @{
                           CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
                           ApplicationId = $ServicePrincipalParams.CertThumbprintParams.AppID;
                           TenantId  = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization Domain is actually required here.
                       }
                       $TeamsParams += $TeamsConnectToTenant
                   }
                   switch ($M365Environment) {
                       "gcchigh" {
                           $TeamsParams += @{'TeamsEnvironmentName'= 'TeamsGCCH';}
                       }
                       "dod" {
                           $TeamsParams += @{'TeamsEnvironmentName'= 'TeamsDOD';}
                       }
                   }
                   Connect-MicrosoftTeams @TeamsParams | Out-Null
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

   # Return connection result with token data for REST-based products
   @{
       ProdAuthFailed  = $ProdAuthFailed
       PBILicenseFound = $PBILicenseFound
       PBILicenseReason = $PBILicenseReason
       SPOAccessToken  = $TokenData.SPOAccessToken
       SPOAdminUrl     = $TokenData.SPOAdminUrl
       PPAccessToken   = $TokenData.PPAccessToken
       PPBaseUrl       = $TokenData.PPBaseUrl
       PBIAccessToken  = $TokenData.PBIAccessToken
       PBIBaseUrl      = $TokenData.PBIBaseUrl
   }
}

function Disconnect-SCuBATenant {
   <#
   .SYNOPSIS
       Disconnect all active M365 connection sessions made by ScubaGear
   .DESCRIPTION
       Forces disconnect of all outstanding open sessions associated with
       M365 product APIs within the current PowerShell session.
       Best used after an ScubaGear run to ensure a new tenant connection is
       used for future ScubaGear runs.
   .Parameter ProductNames
   A list of one or more M365 shortened product names this function will disconnect from. By default this function will disconnect from all possible products ScubaGear can run against.
   .EXAMPLE
   Disconnect-SCuBATenant
   .EXAMPLE
   Disconnect-SCuBATenant -ProductNames teams
   .EXAMPLE
   Disconnect-SCuBATenant -ProductNames aad, exo
   .Functionality
   Public
   #>
   [CmdletBinding()]
   param(
       [ValidateSet("aad", "securitysuite", "exo","powerplatform", "sharepoint", "teams", "powerbi", IgnoreCase = $false)]
       [ValidateNotNullOrEmpty()]
       [string[]]
       $ProductNames = @("aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams", "powerbi")
   )
   $ErrorActionPreference = "SilentlyContinue"

   try {
       $N = 0
       $Len = $ProductNames.Length

       foreach ($Product in $ProductNames) {
           $N += 1
           $Percent = $N*100/$Len
           Write-Progress -Activity "Disconnecting from each service" -Status "Disconnecting from $($Product); $($n) of $($Len) disconnected." -PercentComplete $Percent
           Write-Verbose "Disconnecting from $Product."
           if (($Product -eq "aad") -or ($Product -eq "sharepoint")) {
               Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
               # SharePoint uses REST API with on-demand token - no persistent connection to disconnect
           }
           elseif ($Product -eq "teams") {
               Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue
           }
           elseif ($Product -eq "powerplatform") {
               Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
               # Power Platform uses REST API with on-demand token - no persistent connection to disconnect
           }
           elseif ($Product -eq "powerbi") {
               Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
               # Power BI uses REST API with on-demand token - no persistent connection to disconnect
           }
           elseif (($Product -eq "exo") -or ($Product -eq "securitysuite")) {
               if($Product -eq "securitysuite") {
                   Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
               }
               Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
           }
           else {
               Write-Warning "Product $Product not recognized, skipping..."
           }
       }
       Write-Progress -Activity "Disconnecting from each service" -Status "Done" -Completed

   } catch [System.InvalidOperationException] {
       # Suppress error due to disconnect from service with no active connection
       continue
   } catch {
       Write-Warning "Could not disconnect from $Product`n: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
   } finally {
       $ErrorActionPreference = "Continue"
   }

}

Export-ModuleMember -Function @(
   'Connect-Tenant',
   'Disconnect-SCuBATenant'
)
