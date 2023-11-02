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
   [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", IgnoreCase = $false)]
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

   # Prevent duplicate sign ins
   $EXOAuthRequired = $true
   $SPOAuthRequired = $true
   $AADAuthRequired = $true

   $ProdAuthFailed = @()

   $N = 0
   $Len = $ProductNames.Length

   foreach ($Product in $ProductNames) {
       $N += 1
       $Percent = $N*100/$Len
       $ProgressParams = @{
           'Activity' = "Authenticating to each Product";
           'Status' = "Authenticating to $($Product); $($N) of $($Len) Products authenticated to.";
           'PercentComplete' = $Percent;
       }
       Write-Progress @ProgressParams
       try {
           switch ($Product) {
               "aad" {
                   $GraphScopes = (
                       'User.Read.All',
                       'Policy.Read.All',
                       'Organization.Read.All',
                       'RoleManagement.Read.Directory',
                       'GroupMember.Read.All',
                       'Directory.Read.All'
                   )
                   $GraphParams = @{
                       'ErrorAction' = 'Stop';
                   }
                   if ($ServicePrincipalParams.CertThumbprintParams) {
                       $GraphParams += @{
                           CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
                           ClientID = $ServicePrincipalParams.CertThumbprintParams.AppID;
                           TenantId  = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization also works here
                       }
                   }
                   else {
                       $GraphParams += @{Scopes = $GraphScopes;}
                   }
                   switch ($M365Environment) {
                       "gcchigh" {
                           $GraphParams += @{'Environment' = "USGov";}
                       }
                       "dod" {
                           $GraphParams += @{'Environment' = "USGovDoD";}
                       }
                   }
                   Connect-MgGraph @GraphParams | Out-Null
                   $AADAuthRequired = $false
               }
               {($_ -eq "exo") -or ($_ -eq "defender")} {
                   if ($EXOAuthRequired) {
                       $EXOHelperParams = @{
                           M365Environment = $M365Environment;
                       }
                       if ($ServicePrincipalParams) {
                           $EXOHelperParams += @{ServicePrincipalParams = $ServicePrincipalParams}
                       }
                       Write-Verbose "Defender will require a sign in every single run regardless of what the LogIn parameter is set"
                       Connect-EXOHelper @EXOHelperParams
                       $EXOAuthRequired = $false
                   }
               }
               "powerplatform" {
                   $AddPowerAppsParams = @{
                       'ErrorAction' = 'Stop';
                   }
                   if ($ServicePrincipalParams.CertThumbprintParams) {
                       $AddPowerAppsParams += @{
                           CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
                           ApplicationId = $ServicePrincipalParams.CertThumbprintParams.AppID;
                           TenantID  = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization also works here
                       }
                   }
                   switch ($M365Environment) {
                       "commercial" {
                           $AddPowerAppsParams += @{'Endpoint'='prod';}
                       }
                       "gcc" {
                           $AddPowerAppsParams += @{'Endpoint'='usgov';}
                       }
                       "gcchigh" {
                           $AddPowerAppsParams += @{'Endpoint'='usgovhigh';}
                       }
                       "dod" {
                           $AddPowerAppsParams += @{'Endpoint'='dod';}
                       }
                   }
                   Add-PowerAppsAccount @AddPowerAppsParams | Out-Null
               }
               "sharepoint" {
                   if ($AADAuthRequired) {
                       $LimitedGraphParams = @{
                           'ErrorAction' = 'Stop';
                       }
                       if ($ServicePrincipalParams.CertThumbprintParams) {
                           $LimitedGraphParams += @{
                               CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
                               ClientID = $ServicePrincipalParams.CertThumbprintParams.AppID;
                               TenantId  = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization also works here
                           }
                       }
                       switch ($M365Environment) {
                           "gcchigh" {
                               $LimitedGraphParams += @{'Environment' = "USGov";}
                           }
                           "dod" {
                               $LimitedGraphParams += @{'Environment' = "USGovDoD";}
                           }
                       }
                       Connect-MgGraph @LimitedGraphParams | Out-Null
                       $AADAuthRequired = $false
                   }
                   if ($SPOAuthRequired) {
                       $InitialDomain = (Get-MgBetaOrganization).VerifiedDomains | Where-Object {$_.isInitial}
                       $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]
                       $SPOParams = @{
                           'ErrorAction' = 'Stop';
                       }
                       $PnPParams = @{
                           'ErrorAction' = 'Stop';
                       }
                       switch ($M365Environment) {
                           {($_ -eq "commercial") -or ($_ -eq "gcc")} {
                               $SPOParams += @{
                                   'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint.com";
                               }
                               $PnPParams += @{
                                   'Url'= "$($InitialDomainPrefix)-admin.sharepoint.com";
                               }
                           }
                           "gcchigh" {
                               $SPOParams += @{
                                   'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint.us";
                                   'Region' = "ITAR";
                               }
                               $PnPParams += @{
                                   'Url'= "$($InitialDomainPrefix)-admin.sharepoint.us";
                                   'AzureEnvironment' = 'USGovernmentHigh'
                               }
                           }
                           "dod" {
                               $SPOParams += @{
                                   'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint-mil.us";
                                   'Region' = "ITAR";
                               }
                               $PnPParams += @{
                                   'Url'= "$($InitialDomainPrefix)-admin.sharepoint-mil.us";
                                   'AzureEnvironment' = 'USGovernmentDoD'
                               }
                           }
                       }
                       if ($ServicePrincipalParams.CertThumbprintParams) {
                           $PnPParams += @{
                               Thumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
                               ClientId = $ServicePrincipalParams.CertThumbprintParams.AppID;
                               Tenant  = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization Domain is actually required here.
                           }
                           Connect-PnPOnline @PnPParams | Out-Null
                       }
                       else {
                           Connect-SPOService @SPOParams | Out-Null
                       }
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
           Write-Error "Error establishing a connection with $($Product). $($_)"
           $ProdAuthFailed += $Product
           Write-Warning "$($Product) will be omitted from the output because of failed authentication"
       }
   }
   Write-Progress -Activity "Authenticating to each service" -Status "Ready" -Completed
   $ProdAuthFailed
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
       [ValidateSet("aad", "defender", "exo","powerplatform", "sharepoint", "teams", IgnoreCase = $false)]
       [ValidateNotNullOrEmpty()]
       [string[]]
       $ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
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

               if($Product -eq "sharepoint") {
                   Disconnect-SPOService -ErrorAction SilentlyContinue
                   Disconnect-PnPOnline -ErrorAction SilentlyContinue
               }
           }
           elseif ($Product -eq "teams") {
               Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue
           }
           elseif ($Product -eq "powerplatform") {
               Remove-PowerAppsAccount -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
           }
           elseif (($Product -eq "exo") -or ($Product -eq "defender")) {
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
       Write-Error "ERRROR: Could not disconnect from $Product`n$($Error[0]): "
   } finally {
       $ErrorActionPreference = "Continue"
   }

}

Export-ModuleMember -Function @(
   'Connect-Tenant',
   'Disconnect-SCuBATenant'
)
