package aad_test
import rego.v1

ConditionalAccessPolicies := AADConfig.conditional_access_policies[0]

AADConfig := {
        "conditional_access_policies": [
            {
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
        ]
    }

ScubaConfig := {
    "Aad": {
        "MS.AAD.1.1v1": {
            "CapExclusions": {
                "Users": [],
                "Groups": []
            }
        }
    }
}