package aad
import future.keywords


#
# Policy 1
#--
test_Conditions_Correct if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["Office365"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
test_ExcludeUsers_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["4b8dda31-c541-4e2d-aa7f-5f6e1980dc90"],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                   "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_IncludeGroups_Incorrect if {
    ControlNumber := "AAD 2.2"
    Requirement := "Users detected as high risk SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                  "Applications": {
                        "IncludeApplications": ["All"]
                    },
                "Users": {
                    "IncludeUsers": ["All"],
                    "ExcludeUsers": [],
                    "IncludeGroups": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                    "ExcludeGroups": [],
                    "IncludeRoles": ["All"],
                    "ExcludeRoles": []
                },
                "UserRiskLevels": ["high"]
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_ExcludeGroups_Incorrect if {
    ControlNumber := "AAD 2.2"
    Requirement := "Users detected as high risk SHALL be blocked"

    Output := tests with input as {
    "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                    "IncludeUsers": ["All"],
                    "ExcludeUsers": [],
                    "IncludeGroups": ["All"],
                    "ExcludeGroups": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                    "IncludeRoles": ["All"],
                    "ExcludeRoles": []
                },
                "UserRiskLevels": ["high"]
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_ExcludeRoles_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": ["4b8dda31-c541-4e2d-aa7f-5f6e1980dc90"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                   "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_IncludeRoles_Incorrect if {
    ControlNumber := "AAD 2.2"
    Requirement := "Users detected as high risk SHALL be blocked"

    Output := tests with input as
    {"conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {"IncludeApplications": ["All"]},
                "Users": {
                    "IncludeUsers": ["All"],
                    "ExcludeUsers": [],
                    "IncludeGroups": ["All"],
                    "ExcludeGroups": [],
                    "IncludeRoles": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                    "ExcludeRoles": []
                },
                "UserRiskLevels": ["high"]
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
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_ClientAppTypes_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": [""]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": null
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "IncludeGroups": ["All"],
                        "ExcludeGroups": [],
                        "IncludeRoles": ["All"],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "disabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}