package powerbi
import rego.v1
import data.utils.key.FilterArray
import data.utils.key.Count
import data.utils.report.ReportDetailsBoolean

# Some global variables

PowerbiLicenseErrorMessage := "Power BI license was not found. Unable to evaluate tenant setting."

# object.get returns the actual value from the input if the key exists, otherwise it returns the default value specified (false in this case)
PowerbiLicenseFound := object.get(input, "powerbi_license_found", false)

# Convert tenant settings array into a map keyed by settingName
PowerbiTenantSettings := {
    setting.settingName: setting |
    some setting in object.get(input, "powerbi_tenant_settings", [])
    is_object(setting)
    object.get(setting, "settingName", "") != ""
}

#
# MS.POWERBI.1.1v1
#--

PublishToWebSetting := object.get(PowerbiTenantSettings, "PublishToWeb", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": PublishToWebSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    PublishToWebSetting != null

    status := PublishToWebSetting.enabled == false
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or PublishToWeb are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        PublishToWebSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--

#
# MS.POWERBI.2.1v1
#--

AllowGuestAccessSharedContentSetting := object.get(PowerbiTenantSettings, "AllowGuestUserToAccessSharedContent", null)

AllowGuestAccessDisabled := true if {
    not AllowGuestAccessSharedContentSetting.enabled
} else := false

AllowGuestAccessSecurityGroups := true if {
    Count( object.get(AllowGuestAccessSharedContentSetting, "enabledSecurityGroups", []) ) > 0
} else := false

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": AllowGuestAccessSharedContentSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    AllowGuestAccessSharedContentSetting != null

    CompliantConditions := [
        AllowGuestAccessDisabled,
        AllowGuestAccessSecurityGroups
    ]

    # If either of the compliance conditions are true, then pass the policy.
    status := Count(FilterArray(CompliantConditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or AllowGuestUserToAccessSharedContent are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        AllowGuestAccessSharedContentSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.3.1v1
#--

ExternalSharingV2Setting := object.get(PowerbiTenantSettings, "ExternalSharingV2", null)

ExternalSharingV2Disabled := true if {
    ExternalSharingV2Setting.enabled == false
} else := false

ExternalSharingV2SecurityGroups := true if {
    Count( object.get(ExternalSharingV2Setting, "enabledSecurityGroups", []) ) > 0
} else := false

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": ExternalSharingV2Setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    ExternalSharingV2Setting != null

    conditions := [
        ExternalSharingV2Disabled,
        ExternalSharingV2SecurityGroups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or ExternalSharingV2 are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        ExternalSharingV2Setting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.4.1v1
#--

ServicePrincipalAccessPermissionApisSetting := object.get(PowerbiTenantSettings, "ServicePrincipalAccessPermissionAPIs", null)

ServicePrincipalAccessPermissionApisDisabled := true if {
    ServicePrincipalAccessPermissionApisSetting.enabled == false
} else := false

ServicePrincipalAccessPermissionApisSecurityGroups := true if {
    Count( object.get(ServicePrincipalAccessPermissionApisSetting, "enabledSecurityGroups", []) ) > 0
} else := false

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": ServicePrincipalAccessPermissionApisSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    ServicePrincipalAccessPermissionApisSetting != null

    conditions := [
        ServicePrincipalAccessPermissionApisDisabled,
        ServicePrincipalAccessPermissionApisSecurityGroups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        ServicePrincipalAccessPermissionApisSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--

#
# MS.POWERBI.4.2v1
#--

AllowServicePrincipalsCreateAndUseProfilesSetting := object.get(PowerbiTenantSettings, "AllowServicePrincipalsCreateAndUseProfiles", null)

AllowServicePrincipalsCreateAndUseProfilesDisabled := true if {
    AllowServicePrincipalsCreateAndUseProfilesSetting.enabled == false
} else := false

AllowServicePrincipalsCreateAndUseProfilesSecurityGroups := true if {
    Count( object.get(AllowServicePrincipalsCreateAndUseProfilesSetting, "enabledSecurityGroups", []) ) > 0
} else := false

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": AllowServicePrincipalsCreateAndUseProfilesSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    AllowServicePrincipalsCreateAndUseProfilesSetting != null

    conditions := [
        AllowServicePrincipalsCreateAndUseProfilesDisabled,
        AllowServicePrincipalsCreateAndUseProfilesSecurityGroups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        AllowServicePrincipalsCreateAndUseProfilesSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.5.1v1
#--

BlockResourceKeyAuthenticationSetting := object.get(PowerbiTenantSettings, "BlockResourceKeyAuthentication", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": BlockResourceKeyAuthenticationSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    BlockResourceKeyAuthenticationSetting != null

    status := BlockResourceKeyAuthenticationSetting.enabled == true
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or BlockResourceKeyAuthentication are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        BlockResourceKeyAuthenticationSetting == null
    ]

    some condition in missing_conditions
    condition
}


#
# MS.POWERBI.6.1v1
#--

RScriptVisualSetting := object.get(PowerbiTenantSettings, "RScriptVisual", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": RScriptVisualSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    RScriptVisualSetting != null

    status := RScriptVisualSetting.enabled == false
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or RScriptVisual are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        RScriptVisualSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.7.1v1
#--

EimInformationProtectionEditSetting := object.get(PowerbiTenantSettings, "EimInformationProtectionEdit", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": EimInformationProtectionEditSetting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    PowerbiLicenseFound

    EimInformationProtectionEditSetting != null

    status := EimInformationProtectionEditSetting.enabled == true
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": PowerbiLicenseErrorMessage,
    "RequirementMet": false
} if {
    not PowerbiLicenseFound
}

# Exception case: Missing the specific setting that this policy expects
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON",
    "RequirementMet": false
} if {
    PowerbiLicenseFound

    missing_conditions := [
        count(PowerbiTenantSettings) == 0,
        EimInformationProtectionEditSetting == null
    ]

    some condition in missing_conditions
    condition
}
#--
