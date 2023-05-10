package aad
import future.keywords


#
# Policy 1
#--
test_AdditionalProperties_Correct if {
    PolicyId := "MS.AAD.14.1v1"
    
    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P15D"
                        }
                    }           
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) configured to allow permanent active assignment or expiration period too long"
}

test_AdditionalProperties_Incorrect_V1 if {
    PolicyId := "MS.AAD.14.1v1"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": false,
                            "maximumDuration": "P30D"
                        }
                    }           
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) configured to allow permanent active assignment or expiration period too long:<br/>Global Administrator"
}

test_AdditionalProperties_Incorrect_V2 if {
    PolicyId := "MS.AAD.14.1v1"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P30D"
                        }
                    }           
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) configured to allow permanent active assignment or expiration period too long:<br/>Global Administrator"
}

#
# Policy 2
#--
test_Assignments_Correct if {
    PolicyId := "MS.AAD.14.2v1"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "StartDateTime": "/Date(1660328610000)/"
                    }
                ],
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P30D"
                        }
                    }           
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) assigned to users outside of PIM"
}

test_Assignments_Incorrect if {
    PolicyId := "MS.AAD.14.2v1"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "StartDateTime": null
                    }
                ],
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P30D"
                        }
                    }           
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) assigned to users outside of PIM:<br/>Global Administrator"
}