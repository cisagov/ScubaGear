function Export-PowerPlatformProvider {
    <#
    .Description
    Gets the Power Platform settings that are relevant
    to the SCuBA Power Platform baselines using the Power Platform Administartion
    PowerShell Module
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

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    # Manually importing the module name here to bypass cmdlet name conflicts
    # There are conflicting PowerShell Cmdlet names in EXO and Power Platform
    Import-Module Microsoft.PowerApps.Administration.PowerShell -DisableNameChecking


    $TenantDetails = $Tracker.TryCommand("Get-TenantDetailsFromGraph")
    if ($TenantDetails.Count -gt 0) {
        $TenantID = $TenantDetails.TenantId
    }
    else {
        $TenantID = ""
    }

    # Check if M365Enviromment is set correctly
    $TenantIdConfig = ""
    try {
        $Domains = $TenantDetails.Domains
        $TenantDomain = "Unretrievable"
        $TLD = ".com"
        if (($M365Environment -eq "gcchigh") -or ($M365Environment -eq "dod")) {
            $TLD = ".us"
        }
        foreach ($Domain in $Domains) {
            $Name = $Domain.Name
            $IsInitial = $Domain.initial
            $DomainChecker = $Name.EndsWith(".onmicrosoft$($TLD)") -and !$Name.EndsWith(".mail.onmicrosoft$($TLD)") -and $IsInitial
            if ($DomainChecker){
                $TenantDomain = $Name
            }
        }
        $Uri = "https://login.microsoftonline$($TLD)/$($TenantDomain)/.well-known/openid-configuration"
        $TenantIdConfig = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction "Stop").Content
    }
    catch {
        $EnvCheckWarning = @"
    Power Platform Provider Warning: $($_). Unable to check if M365Environment is set correctly in the Power Platform Provider. This MAY impact the output of the Power Platform Baseline report.
    See the 'Running the Script Behind Some Proxies' in the README.md for a possible solution to this warning.
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

    # MS.POWERPLATFORM.1.1v1, MS.POWERPLATFORM.1.2v1, MS.POWERPLATFORM.5.1v1
    $EnvironmentCreation = ConvertTo-Json @($Tracker.TryCommand("Get-TenantSettings"))

    # MS.POWERPLATFORM.2.1v1, MS.POWERPLATFORM.2.2v1, MS.POWERPLATFORM.2.3v1
    $EnvironmentList = ConvertTo-Json @($Tracker.TryCommand("Get-AdminPowerAppEnvironment"))

    # Check for null return
    if (-not $EnvironmentList) {
        $EnvironmentList = ConvertTo-Json @()
        $Tracker.AddUnSuccessfulCommand("Get-AdminPowerAppEnvironment")
    }

    # has to be tested manually because of http 403 errors
    $DLPPolicies = ConvertTo-Json @()
    try {
        $DLPPolicies = Get-DlpPolicy -ErrorAction "Stop"
        if ($DLPPolicies.StatusCode) {
            $Tracker.AddUnSuccessfulCommand("Get-DlpPolicy")
            $StatusCode = $DLPPolicies.StatusCode
            $Message = $DLPPolicies.Message
            $DLPPolicies = ConvertTo-Json @()
            throw "$($Message) HTTP $($StatusCode) ERROR"
        }
        else {
            $DLPPolicies = ConvertTo-Json -Depth 7 @($DLPPolicies)
            $Tracker.AddSuccessfulCommand("Get-DlpPolicy")
        }
    }
    catch {
        Write-Warning "Error running Get-DlpPolicy: $($_). <= If a HTTP 403 ERROR is thrown then this is because you do not have the proper permissions. Necessary roles for running ScubaGear with Power Platform: Power Platform Administrator with a Power Apps License or Global Admininstrator"
    }

    # MS.POWERPLATFORM.3.1v1
    # has to be tested manually because of http 403 errors
    $TenantIsolation = ConvertTo-Json @()
    try {
        $TenantIso = Get-PowerAppTenantIsolationPolicy -TenantID $TenantID -ErrorAction "Stop"
        if ($TenantIso.StatusCode) {
            $Tracker.AddUnSuccessfulCommand("Get-PowerAppTenantIsolationPolicy")
            $TenantIsolation = ConvertTo-Json @()
            $StatusCode = $DLPPolicies.StatusCode
            $Message = $DLPPolicies.Message
            throw "$($Message) HTTP $($StatusCode) ERROR"
        }
        else {
            $Tracker.AddSuccessfulCommand("Get-PowerAppTenantIsolationPolicy")
            $TenantIsolation = ConvertTo-Json @($TenantIso)
        }
    }
    catch {
        Write-Warning "Error running Get-PowerAppTenantIsolationPolicy: $($_). <= If a HTTP 403 ERROR is thrown then this is because you do not have the proper permissions. Necessary roles for running ScubaGear with Power Platform: Power Platform Administrator with a Power Apps License or Global Admininstrator"
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
    Import-Module Microsoft.PowerApps.Administration.PowerShell -DisableNameChecking

    try {
        $PowerTenantDetails = Get-TenantDetailsFromGraph -ErrorAction "Stop"

        $Domains = $PowerTenantDetails.Domains
        $TenantDomain = "PowerPlatform: Domain Unretrievable"
        $TLD = ".com"
        if (($M365Environment -eq "gcchigh") -or ($M365Environment -eq "dod")) {
            $TLD = ".us"
        }
        foreach ($Domain in $Domains) {
            $Name = $Domain.Name
            $IsInitial = $Domain.initial
            $DomainChecker = $Name.EndsWith(".onmicrosoft$($TLD)") -and !$Name.EndsWith(".mail.onmicrosoft$($TLD)") -and $IsInitial
            if ($DomainChecker){
                $TenantDomain = $Name
            }
        }

        $PowerTenantInfo = @{
            "DisplayName" = $PowerTenantDetails.DisplayName;
            "DomainName" = $TenantDomain;
            "TenantId" = $PowerTenantDetails.TenantId
            "PowerPlatformAdditionalData" = $PowerTenantDetails;
        }
        $PowerTenantInfo = ConvertTo-Json @($PowerTenantInfo) -Depth 4
        $PowerTenantInfo
    }
    catch {
        Write-Warning "Error retrieving Tenant details using Get-PowerPlatformTenantDetail $($_)"
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
