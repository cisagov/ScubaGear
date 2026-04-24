package powerbi_test
import rego.v1

PublishToWeb := {
    "settingName": "PublishToWeb",
    "enabled": false,
    "canSpecifySecurityGroups": false
}

GuestAccess := {
    "settingName": "AllowGuestUserToAccessSharedContent",
    "enabled": false,
    "canSpecifySecurityGroups": false
}

ExternalSharing := {
    "settingName": "ExternalSharingV2",
    "enabled": false,
    "canSpecifySecurityGroups": false
}

ServicePrincipalAPI := {
    "settingName": "ServicePrincipalAccessPermissionAPIs",
    "enabled": true,
    "canSpecifySecurityGroups": true
}

ServicePrincipalProfile := {
    "settingName": "AllowServicePrincipalsCreateAndUseProfiles",
    "enabled": true,
    "canSpecifySecurityGroups": true
}

ResourceKey := {
    "settingName": "BlockResourceKeyAuthentication",
    "enabled": true,
    "canSpecifySecurityGroups": false
}

RScript := {
    "settingName": "RScriptVisual",
    "enabled": false,
    "canSpecifySecurityGroups": false
}

SensitivityLabel := {
    "settingName": "EimInformationProtectionEdit",
    "enabled": true,
    "canSpecifySecurityGroups": false
}

PowerBILicense := true
