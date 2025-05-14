package powerplatform_test
import rego.v1

EnvironmentCreation := {
    "disableEnvironmentCreationByNonAdminUsers": true,
    "disableTrialEnvironmentCreationByNonAdminUsers": true,
    "disablePortalsCreationByNonAdminUsers": true
}

DlpPolicies := {
    "value": [
        {
            "name":  "00000000-0000-0000-0000-000000000000",
            "displayName": "Block Third-Party Connectors",
            "connectorGroups": [
                {
                    "classification": "Confidential",
                    "connectors": [
                        {
                            "id": "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                        }
                    ]
                },
                {
                    "classification": "General",
                    "connectors": [
                        {
                            "id": "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                        }
                    ]
                }
            ],
            "environmentType": "OnlyEnvironments",
            "environments": [
                {
                    "name": "Default-Test Id"
                },
                {
                    "name": "Test1"
                }
            ]
        }
    ]
}

EnvironmentList := [
    {
        "EnvironmentName": "Default-Test Id",
        "IsDefault": true,
    },
    {
        "EnvironmentName": "Test1",
        "IsDefault": false,
    },
    {
        "EnvironmentName": "Test2",
        "IsDefault": false,
    }
]

TenantIsolation := {
    "properties": {
        "isDisabled": false
    }
}