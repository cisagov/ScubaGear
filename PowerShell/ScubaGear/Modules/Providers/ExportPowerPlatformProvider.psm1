function Export-PowerPlatformProvider {
    <#
    .Description
    Gets the Power Platform settings that are relevant
    to the SCuBA Power Platform baselines using the Power Platform Administartion
    PowerShell Module
    .Functionality
    Internal
    #>

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

    # 2.1
    $EnvironmentCreation = ConvertTo-Json @($Tracker.TryCommand("Get-TenantSettings"))

    # 2.2
    $EnvironmentList = ConvertTo-Json @($Tracker.TryCommand("Get-AdminPowerAppEnvironment"))

    # Sanity check
    if (-not $EnvironmentList) {
        $EnvironmentList = @()
        $Tracker.AddUnSuccessfulCommand("Get-AdminPowerAppEnvironment")
    }

    # has to be tested manually because of http 403 errors
    $DLPPolicies = ConvertTo-Json @()
    try {
        $DLPPolicies = Get-DlpPolicy -ErrorAction "Stop"
        if ($DLPPolicies.StatusCode) {
            $Tracker.AddUnSuccessfulCommand("Get-DlpPolicy")
            throw "HTTP ERROR"
        }
        else {
            $DLPPolicies = ConvertTo-Json -Depth 7 @($DLPPolicies)
            $Tracker.AddSuccessfulCommand("Get-DlpPolicy")
        }
    }
    catch {
        Write-Warning "Error running Get-DlpPolicy. $($_). If HTTP ERROR is thrown then this is because you do not have the proper permissions (Global Admin nor Power Platform Administrator with Power Apps for Office 365 License)"
    }

    # 2.3
    # has to be tested manually because of http 403 errors
    $TenantIsolation = ConvertTo-Json @()
    try {
        $TenantIso = Get-PowerAppTenantIsolationPolicy -TenantID $TenantID -ErrorAction "Stop"
        if ($TenantIso.StatusCode) {
            $Tracker.AddUnSuccessfulCommand("Get-PowerAppTenantIsolationPolicy")
            throw "HTTP ERROR"
        }
        else {
            $Tracker.AddSuccessfulCommand("Get-PowerAppTenantIsolationPolicy")
            $TenantIsolation = ConvertTo-Json @($TenantIso)
        }
    }
    catch {
        Write-Warning "Error running Get-PowerAppTenantIsolationPolicy. $($_). If HTTP ERROR is thrown then this is because you do not have the proper permissions (Global Admin nor Power Platform Administrator with Power Apps for Office 365 License)"
    }

    # 2.4 currently has no corresponding PowerShell Cmdlet

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

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
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
