package aad
import future.keywords


#
# Policy 1
#--

test_NoExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptUsers_Correct if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptGroups_Correct if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiUserExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiGroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_2_1": {
                    "CapExclusions": {
                        "Users": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

# Other Conditions tests
test_IncludeApplications_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeUsers_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
        {
            "Conditions": {
                "Applications": {
                    "IncludeApplications": ["All"]
                },
                "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeGroups": [],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]
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
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                },
                "UserRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": [""]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "service_plans": [
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                },
                "UserRiskLevels": ["high"]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "disabled",
            "DisplayName": "Test name"
        }
        ],
        "service_plans": [
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserRiskLevels_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                },
                "UserRiskLevels": [""]
            },
            "GrantControls": {
                "BuiltInControls": ["block"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "service_plans": [
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        },
        {
            "ServicePlanName": "AAD_PREMIUM_P2",
            "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ServicePlans_Incorrect if {
    PolicyId := "MS.AAD.2.1v1"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    },
                    "UserRiskLevels": [""]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "service_plans": [
        {
            "ServicePlanName": "EXCHANGE_S_FOUNDATION",
            "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
        }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "**NOTE: Your tenant does not have an Azure AD Premium P2 license, which is required for this feature**"
}

#
# Policy 2
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.2.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.2 for instructions on manual check"
}