function Export-PowerPlatformProvider {
    <#
    .Description
    Gets the Power Platform settings that are relevant
    to the SCuBA Power Platform baselines using the Power Platform Administartion
    PowerShell Module
    .Functionality
    Internal
    #>

    # Note importing the module might have to be done for every provider as
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
    Import-Module Microsoft.PowerApps.Administration.PowerShell -DisableNameChecking
    $TenantDetails = Get-TenantDetailsFromGraph
    $TenantInfo = @{"DisplayName"=$TenantDetails.DisplayName;}
    $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 4
    $TenantInfo
}
