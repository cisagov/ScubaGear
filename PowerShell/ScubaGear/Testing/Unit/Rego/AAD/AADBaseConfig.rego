package aad_test
import rego.v1
import data.utils.aad.INT_MAX

ConditionalAccessPolicies := {
    "Conditions": {
        "Applications": {
            "IncludeApplications": [
                "All"
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
        ]
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