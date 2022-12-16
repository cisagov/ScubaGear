function Export-PowerPlatformProvider {
    <#
    .Description
    Gets the Power Platform settings that are relevant
    to the SCuBA Power Platform baselines using the Power Platform Administartion
    PowerShell Module
    .Functionality
    Internal
    #>

    # Manually importing the module name here to bypass cmdlet name conflicts
    # There are conflicting PowerShell Cmdlet names in EXO and Power Platform
    Import-Module Microsoft.PowerApps.Administration.PowerShell -DisableNameChecking

    $TenantDetails = Get-TenantDetailsFromGraph
    $TenantID = $TenantDetails.TenantId

    # 2.1
    $EnvironmentCreation = Get-TenantSettings | ConvertTo-Json

    # 2.2
    $EnvironmentList = Get-AdminPowerAppEnvironment | ConvertTo-Json
    $DLPPolicy = Get-DlpPolicy
    $DLPPolicies = ConvertTo-Json -Depth 7 $DLPPolicy

    if (!$EnvironmentList) {
        $EnvironmentList = '"error"'
    }

    if (!$DLPPolicies) {
        $DLPPolicies = '"error"'
    }

    # 2.3
    $TenantIsolation = Get-PowerAppTenantIsolationPolicy -TenantID $TenantID | ConvertTo-Json

    # 2.4 no UI for enabling content security according to doc
    # tenant_id added for testing purposes
    # Note the spacing and the last comma in the json is important
    $json = @"

    "tenant_id": "$TenantID",
    "environment_creation": $EnvironmentCreation,
    "dlp_policies": $DLPPolicies,
    "tenant_isolation": $TenantIsolation,
    "environment_list": $EnvironmentList,
"@

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json = $json -replace "[^\x00-\x7f]","" # remove all characters that are not utf-8
    # https://stackoverflow.com/questions/64093078/how-to-find-unicode-characters-that-are-not-utf8-in-vs-code
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
