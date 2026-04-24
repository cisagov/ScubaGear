package powerbi
import rego.v1
import data.utils.key.FilterArray
import data.utils.powerbi.ApplyLicenseWarning
import data.utils.powerbi.ApplyLicenseWarningString


##################
# MS.POWERBI.1 #
##################

#
# MS.POWERBI.1.1v1
#--

# Pass if PublishToWeb is disabled
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": PublishToWebSetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some PublishToWebSetting in input.publish_to_web_setting
    PublishToWebSetting.settingName == "PublishToWeb"
    Status := PublishToWebSetting.enabled == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.publish_to_web_setting) <= 0
}
#--


##################
# MS.POWERBI.2 #
##################

#
# MS.POWERBI.2.1v1
#--

# Pass if guest access is disabled
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": GuestAccessSetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some GuestAccessSetting in input.guest_access_setting
    GuestAccessSetting.settingName == "AllowGuestUserToAccessSharedContent"
    Status := GuestAccessSetting.enabled == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.guest_access_setting) <= 0
}
#--


##################
# MS.POWERBI.3 #
##################

#
# MS.POWERBI.3.1v1
#--

# Pass if external sharing is disabled
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": ExternalSharingSetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some ExternalSharingSetting in input.external_sharing_setting
    ExternalSharingSetting.settingName == "ExternalSharingV2"
    Status := ExternalSharingSetting.enabled == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.external_sharing_setting) <= 0
}
#--


##################
# MS.POWERBI.4 #
##################

#
# MS.POWERBI.4.1v1
#--

# Pass if service principal API access is enabled and restricted to security groups
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": [ServicePrincipalAPISetting.enabled, ServicePrincipalAPISetting.canSpecifySecurityGroups],
    "ReportDetails": ApplyLicenseWarningString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    some ServicePrincipalAPISetting in input.service_principal_api_setting
    ServicePrincipalAPISetting.settingName == "ServicePrincipalAccessPermissionAPIs"

    Conditions := [
        ServicePrincipalAPISetting.enabled == true,
        ServicePrincipalAPISetting.canSpecifySecurityGroups == true
    ]
    Status := count(FilterArray(Conditions, false)) == 0
    ErrorMessage := "Service principal API access must be enabled and restricted to security groups"
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.4.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.service_principal_api_setting) <= 0
}
#--

#
# MS.POWERBI.4.2v1
#--

# Pass if service principal profile creation is enabled and restricted to security groups
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": [ServicePrincipalProfileSetting.enabled, ServicePrincipalProfileSetting.canSpecifySecurityGroups],
    "ReportDetails": ApplyLicenseWarningString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    some ServicePrincipalProfileSetting in input.service_principal_profile_setting
    ServicePrincipalProfileSetting.settingName == "AllowServicePrincipalsCreateAndUseProfiles"

    Conditions := [
        ServicePrincipalProfileSetting.enabled == true,
        ServicePrincipalProfileSetting.canSpecifySecurityGroups == true
    ]
    Status := count(FilterArray(Conditions, false)) == 0
    ErrorMessage := "Service principal profile creation must be enabled and restricted to security groups"
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.service_principal_profile_setting) <= 0
}
#--


##################
# MS.POWERBI.5 #
##################

#
# MS.POWERBI.5.1v1
#--

# Pass if ResourceKey authentication is blocked (enabled means blocked)
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": ResourceKeySetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some ResourceKeySetting in input.resource_key_setting
    ResourceKeySetting.settingName == "BlockResourceKeyAuthentication"
    Status := ResourceKeySetting.enabled == true
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.resource_key_setting) <= 0
}
#--


##################
# MS.POWERBI.6 #
##################

#
# MS.POWERBI.6.1v1
#--

# Pass if R and Python visuals are disabled
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": RScriptSetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some RScriptSetting in input.rscript_setting
    RScriptSetting.settingName == "RScriptVisual"
    Status := RScriptSetting.enabled == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.6.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.rscript_setting) <= 0
}
#--


##################
# MS.POWERBI.7 #
##################

#
# MS.POWERBI.7.1v1
#--

# Pass if sensitivity labels are enabled
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": SensitivityLabelSetting.enabled,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    some SensitivityLabelSetting in input.sensitivity_label_setting
    SensitivityLabelSetting.settingName == "EimInformationProtectionEdit"
    Status := SensitivityLabelSetting.enabled == true
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERBI.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Invoke-RestMethod"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.sensitivity_label_setting) <= 0
}
#--
