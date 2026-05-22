package powerbi_test

import rego.v1

PowerbiTenantSettingsJson := {
    "powerbi_license_found": true,
    "powerbi_tenant_settings": PowerbiTenantSettings,
}

PowerbiTenantSettings := [
    PublishToWebSetting,
    AllowGuestUserToAccessSharedContentSetting,
    ExternalSharingV2Setting,
    ServicePrincipalAccessPermissionAPIsSetting,
    AllowServicePrincipalsCreateAndUseProfilesSetting,
    BlockResourceKeyAuthenticationSetting,
    RScriptVisualSetting,
    EimInformationProtectionEditSetting,
]

PublishToWebSetting := {
    "settingName": "PublishToWeb",
    "title": "Publish to web",
    "enabled": false,
    "canSpecifySecurityGroups": true,
    "tenantSettingGroup": "Export and sharing settings",
    "properties": [
        {
            "name": "CreateP2w",
            "value": "false",
            "type": "Boolean",
        },
    ],
}

AllowGuestUserToAccessSharedContentSetting := {
    "settingName": "AllowGuestUserToAccessSharedContent",
    "title": "Allow Azure Active Directory guest users to access Power BI",
    "enabled": false,
    "canSpecifySecurityGroups": true,
    "tenantSettingGroup": "Export and sharing settings",
}

ExternalSharingV2Setting := {
    "settingName": "ExternalSharingV2",
    "title": "Users can invite guest users to collaborate through item sharing and permissions",
    "enabled": true,
    "canSpecifySecurityGroups": true,
    "tenantSettingGroup": "Export and sharing settings",
}

ServicePrincipalAccessPermissionAPIsSetting := {
    "settingName": "ServicePrincipalAccessPermissionAPIs",
    "title": "Service principals can call Fabric public APIs",
    "enabled": true,
    "canSpecifySecurityGroups": true,
    "enabledSecurityGroups": PowerbiEnabledSecurityGroups,
    "tenantSettingGroup": "Developer settings",
}

PowerbiEnabledSecurityGroups := [
    {
        "graphId": "56100b38-aabf-4bb2-8b0f-60ef6a6c4dd7",
        "name": "PowerBI-Test",
    },
    {
        "graphId": "152036d1-b992-46e8-878d-623fbbc2a6a8",
        "name": "Power BI Principals",
    },
]

AllowServicePrincipalsCreateAndUseProfilesSetting := {
    "settingName": "AllowServicePrincipalsCreateAndUseProfiles",
    "title": "Allow service principals to create and use profiles",
    "enabled": false,
    "canSpecifySecurityGroups": true,
    "tenantSettingGroup": "Developer settings",
}

BlockResourceKeyAuthenticationSetting := {
    "settingName": "BlockResourceKeyAuthentication",
    "title": "Block ResourceKey Authentication",
    "enabled": true,
    "canSpecifySecurityGroups": false,
    "tenantSettingGroup": "Developer settings",
}

RScriptVisualSetting := {
    "settingName": "RScriptVisual",
    "title": "Interact with and share R and Python visuals",
    "enabled": false,
    "canSpecifySecurityGroups": false,
    "tenantSettingGroup": "R and Python visuals settings",
}

EimInformationProtectionEditSetting := {
    "settingName": "EimInformationProtectionEdit",
    "title": "Allow users to apply sensitivity labels for content",
    "enabled": true,
    "canSpecifySecurityGroups": false,
    "tenantSettingGroup": "Information protection",
}

GetPowerBISettingIndex(setting_name) := idx if {
    some idx
    PowerbiTenantSettingsJson.powerbi_tenant_settings[idx].settingName == setting_name
}

PowerbiLicenseErrorMessage := "Power BI license was not found. Unable to evaluate tenant setting."