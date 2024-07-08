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
            "environments": [
                {
                    "name": "Default-Test Id"
                }
            ]
        }
    ]
}

EnvironmentList := {
    "EnvironmentName": "Default-Test Id"
}

TenantIsolation := {
    "properties": {
        "isDisabled": false
    }
}