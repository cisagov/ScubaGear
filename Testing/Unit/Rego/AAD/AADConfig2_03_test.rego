package aad
import future.keywords


#
# Policy 1
#--
test_Conditions_Correct if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {"IncludeUsers": ["All"]},
                "SignInRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["Office365"]},
                "Users": {"IncludeUsers": ["All"]},
                "SignInRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {"IncludeUsers": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]},
                "SignInRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_SignInRiskLevels_Incorrect if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {"IncludeUsers": ["All"]},
                "SignInRiskLevels": [""]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {"IncludeUsers": ["All"]},
                "SignInRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": [""]
            },
            "State": "enabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.3"
    Requirement := "Sign-ins detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {"IncludeUsers": ["All"]},
                "SignInRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "disabled",
            "DisplayName": "Test name"
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}