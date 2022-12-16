package aad
import future.keywords


#
# Policy 1
#--
test_AdditionalProperties_Correct if {
    ControlNumber := "AAD 2.15"
    Requirement := "Activation of highly privileged roles SHOULD require approval"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Approval_EndUser_Assignment",
                        "AdditionalProperties":  {
                            "setting": {
                                "isApprovalRequired" : true
                            }
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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) that do not require approval to activate found"
}

test_AdditionalProperties_Incorrect if {
    ControlNumber := "AAD 2.15"
    Requirement := "Activation of highly privileged roles SHOULD require approval"

    Output := tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Approval_EndUser_Assignment",
                        "AdditionalProperties":  {
                            "setting": {
                                "isApprovalRequired" : false
                            }
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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) that do not require approval to activate found:<br/>Global Administrator"
}