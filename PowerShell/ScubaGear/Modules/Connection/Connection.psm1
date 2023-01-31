function Connect-Tenant {
     <#
    .Description
    This function uses the various PowerShell modules to establish
    a connection to an M365 Tenant associated with provided
    credentials
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", IgnoreCase = $false)]
    [string[]]
    $ProductNames,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
    [string]
    $M365Environment,

    [Parameter(Mandatory = $false)]
    [hashtable]
    $CertThumbprintParams
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
                        'UserAuthenticationMethod.Read.All',
                        'RoleManagement.Read.Directory',
                        'GroupMember.Read.All',
                        'Directory.Read.All'
                    )
                    $GraphParams = @{
                        'Scopes' = $GraphScopes;
                        'ErrorAction' = 'Stop';
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
                    Select-MgProfile -Name "Beta" -ErrorAction "Stop" | Out-Null
                    $AADAuthRequired = $false
                }
                {($_ -eq "exo") -or ($_ -eq "defender")} {
                    if ($EXOAuthRequired) {
                        $EXOHelperParams = @{
                            M365Environment = $M365Environment;
                        }
                        if ($CertThumbprintParams) {
                            $EXOHelperParams += @{CertThumbprintParams = $CertThumbprintParams}
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
                {($_ -eq "onedrive") -or ($_ -eq "sharepoint")} {
                    if ($AADAuthRequired) {
                        $LimitedGraphParams = @{
                            'ErrorAction' = 'Stop';
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
                        Select-MgProfile -Name "Beta" -ErrorAction "Stop" | Out-Null
                        $AADAuthRequired = $false
                    }
                    if ($SPOAuthRequired) {
                        $InitialDomain = (Get-MgOrganization).VerifiedDomains | Where-Object {$_.isInitial}
                        $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]
                        $SPOParams = @{
                            'ErrorAction' = 'Stop';
                        }
                        switch ($M365Environment) {
                            {($_ -eq "commercial") -or ($_ -eq "gcc")} {
                                $SPOParams += @{
                                    'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint.com";
                                }
                            }
                            "gcchigh" {
                                $SPOParams += @{
                                    'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint.us";
                                    'Region' = "ITAR";
                                }
                            }
                            "dod" {
                                $SPOParams += @{
                                    'Url'= "https://$($InitialDomainPrefix)-admin.sharepoint-mil.us";
                                    'Region' = "ITAR";
                                }
                            }
                        }
                        Connect-SPOService @SPOParams | Out-Null
                        $SPOAuthRequired = $false
                    }
                }
                "teams" {
                    $TeamsParams = @{'ErrorAction'= 'Stop'}
                    if ($CertThumbprintParams) {
                        try {
                            $TeamsConnectToTenant = @{
                                CertificateThumbPrint = $CertThumbprintParams.CertificateThumbprint;
                                ApplicationId = $CertThumbprintParams.AppId;
                                TenantId  = $CertThumbprintParams.Organization; # Yes. Teams PowerShell confuses Tenant ID and Organization Domain
                            }
                            $TeamsParams += $TeamsConnectToTenant
                        }
                        catch {
                            Write-Warning "Unable to retrieve Tenant ID for Teams authenticatio with URI. This may be caused by proxy error see 'Running the Script Behind Some Proxies' in the README for a solution. $($_)"
                        }
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
        [ValidateSet("aad", "defender", "exo", "onedrive","powerplatform", "sharepoint", "teams", IgnoreCase = $false)]
        [string[]]
        $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
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
            if (($Product -eq "aad") -or ($Product -eq "onedrive") -or ($Product -eq "sharepoint")) {
                Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

                if($Product -eq "sharepoint") {
                    Disconnect-SPOService -ErrorAction SilentlyContinue
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
