Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

function Export-PowerPlatformProvider {
    <#
    .Description
    Gets the Power Platform settings that are relevant
    to the SCuBA Power Platform baselines using direct REST API calls
    authenticated via MSAL.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [hashtable]
        $ServicePrincipalParams = @{}
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "PowerPlatformRestHelper.psm1")
    $Tracker = Get-CommandTracker

    $TenantDetails = $Tracker.TryCommand("Get-MgBetaOrganization", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})
    $TenantId = if ($TenantDetails.Id) { $TenantDetails.Id } else { "" }

    $DomainInfo = Get-TenantDomainInfo -TenantDetails $TenantDetails -M365Environment $M365Environment
    Test-M365EnvironmentConfiguration -TenantDomain $DomainInfo.TenantDomain -TLD $DomainInfo.TLD -M365Environment $M365Environment

    # Acquire Power Platform access token - service principal or interactive
    $BaseUrl = Get-PowerPlatformBaseUrl -M365Environment $M365Environment
    $AccessToken = $null
    try {
        if ($ServicePrincipalParams.CertThumbprintParams) {
            $AccessToken = Get-PowerPlatformAccessToken `
                -CertificateThumbprint $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint `
                -AppID $ServicePrincipalParams.CertThumbprintParams.AppID `
                -Tenant $ServicePrincipalParams.CertThumbprintParams.Organization `
                -M365Environment $M365Environment
        }
        else {
            # Interactive browser authentication - use tenant domain for authority
            $InitialDomain = $TenantDetails.VerifiedDomains | Where-Object { $_.isInitial }
            $TenantName = $InitialDomain.Name
            $AccessToken = Get-PowerPlatformAccessTokenInteractive `
                -Tenant $TenantName `
                -M365Environment $M365Environment
        }
    }
    catch {
        Write-Warning "Failed to acquire Power Platform access token: $($_.Exception.Message)"
    }

    # MS.POWERPLATFORM.1.1v1, MS.POWERPLATFORM.1.2v1, MS.POWERPLATFORM.5.1v1, MS.POWERPLATFORM.6.1v1
    $EnvironmentCreation = ConvertTo-Json @()
    try {
        $TenantSettings = Get-PowerPlatformTenantSettingsRest -BaseUrl $BaseUrl -AccessToken $AccessToken
        $EnvironmentCreation = ConvertTo-Json -Depth 10 @($TenantSettings)
        $Tracker.AddSuccessfulCommand("Get-TenantSettings")
    }
    catch {
        Write-Warning "Error running Get-TenantSettings (REST): $($_)"
        $Tracker.AddUnSuccessfulCommand("Get-TenantSettings")
    }

    # MS.POWERPLATFORM.2.1v1, MS.POWERPLATFORM.2.2v1, MS.POWERPLATFORM.2.3v1
    $EnvironmentList = ConvertTo-Json @()
    try {
        $Environments = Get-PowerPlatformEnvironmentsRest -BaseUrl $BaseUrl -AccessToken $AccessToken
        $EnvironmentList = ConvertTo-Json -Depth 4 @($Environments)
        $Tracker.AddSuccessfulCommand("Get-AdminPowerAppEnvironment")
    }
    catch {
        Write-Warning "Error running Get-AdminPowerAppEnvironment (REST): $($_)"
        $Tracker.AddUnSuccessfulCommand("Get-AdminPowerAppEnvironment")
    }

    # has to be tested manually because of http 403 errors
    $DLPPolicies = ConvertTo-Json @()
    try {
        $DlpResponse = Get-PowerPlatformDlpPoliciesRest -BaseUrl $BaseUrl -AccessToken $AccessToken
        $DLPPolicies = ConvertTo-Json -Depth 10 @($DlpResponse)
        $Tracker.AddSuccessfulCommand("Get-DlpPolicy")
    }
    catch {
        Write-Warning "Error running Get-DlpPolicy (REST): $($_). <= If a HTTP 403 ERROR is thrown then this is because you do not have the proper permissions. Necessary roles for running ScubaGear with Power Platform: Power Platform Administrator with a Power Apps License or Global Admininstrator"
    }

    # MS.POWERPLATFORM.3.1v1
    # has to be tested manually because of http 403 errors
    $TenantIsolation = ConvertTo-Json @()
    try {
        $TenantIso = Get-PowerPlatformTenantIsolationRest -BaseUrl $BaseUrl -AccessToken $AccessToken -TenantId $TenantId
        $TenantIsolation = ConvertTo-Json -Depth 4 @($TenantIso)
        $Tracker.AddSuccessfulCommand("Get-PowerAppTenantIsolationPolicy")
    }
    catch {
        Write-Warning "Error running Get-PowerAppTenantIsolationPolicy (REST): $($_). <= If a HTTP 403 ERROR is thrown then this is because you do not have the proper permissions. Necessary roles for running ScubaGear with Power Platform: Power Platform Administrator with a Power Apps License or Global Admininstrator"
    }

    # MS.POWERPLATFORM.3.2v1 currently has no corresponding PowerShell Cmdlet

    # MS.POWERPLATFORM.4.1v1 currently has no corresponding PowerShell Cmdlet

    $PowerPlatformSuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $PowerPlatformUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # tenant_id added for testing purposes
    # Note the spacing and the last comma in the json is important
    $json = @"
    "tenant_id": "$TenantID",
    "environment_creation": $EnvironmentCreation,
    "dlp_policies": $DLPPolicies,
    "tenant_isolation": $TenantIsolation,
    "environment_list": $EnvironmentList,
    "powerplatform_successful_commands": $PowerPlatformSuccessfulCommands,
    "powerplatform_unsuccessful_commands": $PowerPlatformUnSuccessfulCommands,
"@

    $json = $json -replace "[^\x00-\x7f]","" # remove all characters that are not utf-8
    $json
}

function Get-TenantDomainInfo {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$TenantDetails,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    $TenantDomain = "Unretrievable"
    $TLD = ".com"
    if (($M365Environment -eq "gcchigh") -or ($M365Environment -eq "dod")) {
        $TLD = ".us"
    }

    foreach ($Domain in $TenantDetails.VerifiedDomains) {
        $Name = $Domain.Name
        $IsInitial = $Domain.IsInitial
        $DomainChecker = $Name.EndsWith(".onmicrosoft$($TLD)") -and !$Name.EndsWith(".mail.onmicrosoft$($TLD)") -and $IsInitial
        if ($DomainChecker){
            $TenantDomain = $Name
        }
    }

    return @{
        TenantDomain = $TenantDomain;
        TLD = $TLD;
    }
}

function Test-M365EnvironmentConfiguration {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantDomain,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TLD,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    $TenantIdConfig = ""
    try {
        $Uri = "https://login.microsoftonline$($TLD)/$($TenantDomain)/.well-known/openid-configuration"
        $TenantIdConfig = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction "Stop").Content
    }
    catch {
        $EnvCheckWarning = @"
    Power Platform Provider Warning: $($_). Unable to check if M365Environment is set correctly in the Power Platform Provider. This MAY impact the output of the Power Platform Baseline report.
    See https://github.com/cisagov/ScubaGear/blob/main/docs/troubleshooting/proxy.md for a possible solution to this warning.
"@
        Write-Warning $EnvCheckWarning
    }

    # Commercial: "tenant_region_scope":"NA"
    # GCC: "tenant_region_scope":"NA","tenant_region_sub_scope":"GCC",
    # GCCHigh: "tenant_region_scope":"USGov","tenant_region_sub_scope":"DODCON"
    # DoD: "tenant_region_scope":"USGov","tenant_region_sub_scope":"DOD"
    try {
        if ($TenantIdConfig -ne "") {
            $TenantIdConfigJson = ConvertFrom-Json $TenantIdConfig
            $RegionScope = $TenantIdConfigJson.tenant_region_scope
            $RegionSubScope = $TenantIdConfigJson.tenant_region_sub_scope
            if (-not $RegionSubScope) {
                $RegionSubScope = ""
            }

            $CheckRScope = $true
            $CheckRSubScope = $true
            if ($RegionScope -eq "NA" -or $RegionScope -eq "USGov" -or $RegionScope -eq "USG") {
                switch ($M365Environment) {
                    "commercial" {
                        $CheckRScope = $RegionScope -eq "NA"
                        $CheckRSubScope = $RegionSubScope -eq ""
                    }
                    "gcc" {
                        $CheckRScope = $RegionScope -eq "NA"
                        $CheckRSubScope = $RegionSubScope -eq "GCC"
                    }
                    "gcchigh" {
                        $CheckRScope = $RegionScope -eq "USGov" -or $RegionScope -eq "USG"
                        $CheckRSubScope = $RegionSubScope -eq "DODCON"
                    }
                    "dod" {
                        $CheckRScope = $RegionScope -eq "USGov" -or $RegionScope -eq "USG"
                        $CheckRSubScope = $RegionSubScope -eq "DOD"
                    }
                    default {
                        throw "Unsupported or invalid M365Environment argument"
                    }
                }
            }

            # spacing is intentional
            $EnvErrorMessage = @"
"Power Platform Provider ERROR: The M365Environment parameter value is not set correctly which WILL cause the Power Platform report to display incorrect values.
            ---------------------------------------
            M365Environment Parameter value: $($M365Environment)
            Your tenant's OpenId-Configuration: tenant_region_scope: $($RegionScope), tenant_region_sub_scope: $($RegionSubScope)
"@

        if (-not ($CheckRScope -and $CheckRSubScope)) {
                throw $EnvErrorMessage
            }
        }
    }
    catch {

        $FullEnvErrorMessage = @"
$($_)
        ---------------------------------------
        Rerun ScubaGear with the correct M365Environment parameter value
        by looking at your tenant's OpenId-Configuration displayed above and
        contrast it with the mapped values in the table below
        M365Enviroment => OpenId-Configuration
        ---------------------------------------
        commercial: tenant_region_scope:NA, tenant_region_sub_scope:
        gcc: tenant_region_scope:NA, tenant_region_sub_scope: GCC
        gcchigh : tenant_region_scope:USGov, tenant_region_sub_scope: DODCON
        dod: tenant_region_scope:USGov, tenant_region_sub_scope: DOD
        ---------------------------------------
        Example Rerun for gcc tenants: Invoke-Scuba -M365Environment gcc
"@
        throw $FullEnvErrorMessage
    }
}

function Get-PowerPlatformTenantDetail {
    <#
    .Description
    Gets the M365 tenant details using the Power Platform PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    try {
        $TenantDetails = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value
        $DomainInfo = Get-TenantDomainInfo -TenantDetails $TenantDetails -M365Environment $M365Environment

        $PowerTenantInfo = @{
            "DisplayName" = $TenantDetails.DisplayName;
            "DomainName" = $DomainInfo.TenantDomain;
            "TenantId" = $TenantDetails.TenantId;
            "PowerPlatformAdditionalData" = $TenantDetails;
        }
        $PowerTenantInfo = ConvertTo-Json @($PowerTenantInfo) -Depth 4
        $PowerTenantInfo
    }
    catch {
        Write-Warning "Error retrieving Tenant details using Get-PowerPlatformTenantDetail: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        $PowerTenantInfo = @{
            "DisplayName" = "Error retrieving Display name";
            "DomainName" = "Error retrieving Domain name";
            "TenantId" = "Error retrieving Tenant ID";
            "PowerPlatformAdditionalData" = "Error retrieving additional data";
        }
        $PowerTenantInfo = ConvertTo-Json @($PowerTenantInfo) -Depth 4
        $PowerTenantInfo
    }
}
