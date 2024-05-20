package aad_test
import rego.v1
import data.utils.aad.INT_MAX

ConditionalAccessPolicies := {
    "Conditions": {
        "Applications": {
            "IncludeApplications": [
                "All"
            ],
            "ExcludeApplications": [],
            "IncludeUserActions": [
                "urn:user:registersecurityinfo"
            ]
        },
        "Users": {
            "IncludeUsers": [
                "All"
            ],
            "ExcludeUsers": [],
            "ExcludeGroups": [],
            "ExcludeRoles": []
        },
        "UserRiskLevels": [
            "high"
        ],
        "SignInRiskLevels": [
            "high"
        ],
        "ClientAppTypes": [
            "other",
            "exchangeActiveSync"
        ]
    },
    "GrantControls": {
        "BuiltInControls": [
            "block"
        ],
        "AuthenticationStrength": {
            "AllowedCombinations": [
                "windowsHelloForBusiness",
                "fido2",
                "x509CertificateMultiFactor"
            ]
        }
    },
    "State": "enabled",
    "DisplayName": "Test block Legacy Authentication"
}

ScubaConfig := {
            "CapExclusions": {
                "Users": [],
                "Groups": []
            }
        }

ServicePlans := [
    {
        "ServicePlanName": "EXCHANGE_S_FOUNDATION",
        "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
    },
    {
        "ServicePlanName": "AAD_PREMIUM_P2",
        "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
    }
]

AuthorizationPolicies := {
    "DefaultUserRolePermissions": {
        "AllowedToCreateApps": false
    },
    "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [
        "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
        "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team"
    ],
    "GuestUserRoleId": "2af84b1e-32c8-42b7-82bc-daa82404023b",
    "AllowInvitesFrom" : "adminsAndGuestInviters",
    "Id": "authorizationPolicy"
}

DirectorySettings := {
    "DisplayName": "Setting display name",
    "Values": [
        {
            "Name":  "EnableAdminConsentRequests",
            "Value":  "true"
        },
        {
            "Name": "EnableGroupSpecificConsent",
            "Value": "false"
        }
    ]
}

DomainSettings := [
    {
        "Id" : "test.url.com",
        "PasswordValidityPeriodInDays" : INT_MAX,
        "IsVerified" : true
    },
    {
        "Id" : "test1.url.com",
        "PasswordValidityPeriodInDays" : INT_MAX,
        "IsVerified" : true
    },
    {
        "Id" : "test2.url.com",
        "PasswordValidityPeriodInDays" : INT_MAX,
        "IsVerified" : true
    }
]

AuthenticationMethod := {
    "authentication_method_policy": {
        "PolicyMigrationState": "migrationComplete"
    },
    "authentication_method_feature_settings": [
        {
            "Id":  "MicrosoftAuthenticator",
            "State": "enabled",
            "ExcludeTargets":  [],
            "AdditionalProperties":  {
                "@odata.type":  "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration",
                "isSoftwareOathEnabled":  false,
                "featureSettings":  {
                    "displayAppInformationRequiredState":  {
                        "state":  "enabled",
                        "includeTarget":  {
                            "targetType":  "group",
                            "id":  "all_users"
                        },
                        "excludeTarget":  {
                            "targetType":  "group",
                            "id":  "00000000-0000-0000-0000-000000000000"
                        }
                    },
                    "displayLocationInformationRequiredState":  {
                        "state":  "enabled",
                        "includeTarget":  {
                            "targetType":  "group",
                            "id":  "all_users"
                        },
                        "excludeTarget":  {
                            "targetType":  "group",
                            "id":  "00000000-0000-0000-0000-000000000000"
                        }
                    }
                },
                "includeTargets@odata.context":  "https://graph.microsoft.com/beta/$metadata#policies/authenticationMethodsPolicy/authenticationMethodConfigurations(\u0027MicrosoftAuthenticator\u0027)/microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration/includeTargets",
                "includeTargets":  [
                    {
                        "targetType":  "group",
                        "id":  "all_users",
                        "isRegistrationRequired":  false,
                        "authenticationMode":  "any"
                    }
                ]
            }
        },
        {
            "Id": "Sms",
            "State": "disabled"
        },
        {
            "Id":  "Voice",
            "State":  "disabled"
        },
        {
            "Id":  "Email",
            "State": "disabled"
        }
    ]
}

PrivilegedRoles := [
    {
        "RoleTemplateId": "Role1",
        "DisplayName": "Global Administrator"
    },
    {
        "RoleTemplateId": "Role2",
        "DisplayName": "Privileged Role Administrator"
    }
]