package powerbi
import rego.v1
import data.utils.key.FilterArray
import data.utils.key.Count
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsString


# Some global variables

powerbi_license_error_message := "Power BI license was not found. Unable to evaluate tenant setting."

# object.get returns the actual value from the input if the key exists, otherwise it returns the default value specified (false in this case)
powerbi_license_found := object.get(input, "powerbi_license_found", false)

# Convert tenant settings array into a map keyed by settingName
powerbi_tenant_settings := {
    setting.settingName: setting |
    some setting in object.get(input, "powerbi_tenant_settings", [])
    is_object(setting)
    object.get(setting, "settingName", "") != ""
}

#
# MS.POWERBI.1.1v1
#--

publish_to_web_setting := object.get(powerbi_tenant_settings, "PublishToWeb", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": publish_to_web_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    publish_to_web_setting != null

    status := publish_to_web_setting.enabled == false
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        publish_to_web_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--

#
# MS.POWERBI.2.1v1
#--

allow_guest_access_shared_content_setting := object.get(powerbi_tenant_settings, "AllowGuestUserToAccessSharedContent", null)

allow_guest_access_disabled := allow_guest_access_shared_content_setting.enabled == false

allow_guest_access_security_groups := Count(
    object.get(allow_guest_access_shared_content_setting, "enabledSecurityGroups", [])
) > 0

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": allow_guest_access_shared_content_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    allow_guest_access_shared_content_setting != null

    CompliantConditions := [
        allow_guest_access_disabled,
        allow_guest_access_security_groups
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
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        allow_guest_access_shared_content_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.3.1v1
#--

external_sharing_v2_setting := object.get(powerbi_tenant_settings, "ExternalSharingV2", null)

external_sharing_v2_disabled := external_sharing_v2_setting.enabled == false

external_sharing_v2_security_groups := Count(
    object.get(external_sharing_v2_setting, "enabledSecurityGroups", [])
) > 0

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": external_sharing_v2_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    external_sharing_v2_setting != null

    conditions := [
        external_sharing_v2_disabled,
        external_sharing_v2_security_groups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        external_sharing_v2_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.4.1v1
#--

service_principal_access_permission_apis_setting := object.get(powerbi_tenant_settings, "ServicePrincipalAccessPermissionAPIs", null)

service_principal_access_permission_apis_disabled := service_principal_access_permission_apis_setting.enabled == false

service_principal_access_permission_apis_security_groups := Count(
    object.get(service_principal_access_permission_apis_setting, "enabledSecurityGroups", [])
) > 0

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": service_principal_access_permission_apis_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    service_principal_access_permission_apis_setting != null

    conditions := [
        service_principal_access_permission_apis_disabled,
        service_principal_access_permission_apis_security_groups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        service_principal_access_permission_apis_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--

#
# MS.POWERBI.4.2v1
#--

allow_service_principals_create_and_use_profiles_setting := object.get(powerbi_tenant_settings, "AllowServicePrincipalsCreateAndUseProfiles", null)

allow_service_principals_create_and_use_profiles_disabled := allow_service_principals_create_and_use_profiles_setting.enabled == false

allow_service_principals_create_and_use_profiles_security_groups := Count(
    object.get(allow_service_principals_create_and_use_profiles_setting, "enabledSecurityGroups", [])
) > 0

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": allow_service_principals_create_and_use_profiles_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    allow_service_principals_create_and_use_profiles_setting != null

    conditions := [
        allow_service_principals_create_and_use_profiles_disabled,
        allow_service_principals_create_and_use_profiles_security_groups
    ]

    status := Count(FilterArray(conditions, true)) > 0
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        allow_service_principals_create_and_use_profiles_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.5.1v1
#--

block_resource_key_authentication_setting := object.get(powerbi_tenant_settings, "BlockResourceKeyAuthentication", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": block_resource_key_authentication_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    block_resource_key_authentication_setting != null

    status := block_resource_key_authentication_setting.enabled == true
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        block_resource_key_authentication_setting == null
    ]

    some condition in missing_conditions
    condition
}


#
# MS.POWERBI.6.1v1
#--

r_script_visual_setting := object.get(powerbi_tenant_settings, "RScriptVisual", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": r_script_visual_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    r_script_visual_setting != null

    status := r_script_visual_setting.enabled == false
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        r_script_visual_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--


#
# MS.POWERBI.7.1v1
#--

eim_information_protection_edit_setting := object.get(powerbi_tenant_settings, "EimInformationProtectionEdit", null)

# Core policy: PowerBI License found and setting was found in JSON
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": eim_information_protection_edit_setting.enabled,
    "ReportDetails": ReportDetailsBoolean(status),
    "RequirementMet": status
} if {
    powerbi_license_found

    eim_information_protection_edit_setting != null

    status := eim_information_protection_edit_setting.enabled == true
}

# Exception case: No PowerBI license found
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "No License",
    "ReportDetails": powerbi_license_error_message,
    "RequirementMet": false
} if {
    not powerbi_license_found
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
    powerbi_license_found

    missing_conditions := [
        count(powerbi_tenant_settings) == 0,
        eim_information_protection_edit_setting == null
    ]

    some condition in missing_conditions
    condition
}
#--
