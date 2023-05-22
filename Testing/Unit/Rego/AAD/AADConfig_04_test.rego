package aad
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--

test_NoExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptUsers_Correct if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                    "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionConditions_Correct if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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
    PolicyId := "MS.AAD.4.1v1"

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
                }
            },
            "GrantControls": {
                "BuiltInControls": ["mfa"]
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_4_1": {
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

# Other conditions
test_ConditionalAccessPolicies_Correct if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput)>= 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy require MFA for All Users. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users, but not all Apps"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeUsers_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"


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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [""]
                },
                "State": "enabled",
                "DisplayName": "Test Policy does not require MFA"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    PolicyId := "MS.AAD.4.1v1"

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
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "disabled",
                "DisplayName": "Test Policy is correct, but not enabled"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.AAD.4.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.AAD.4.3v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 4
#--
test_NotImplemented_Correct_V3 if {
    PolicyId := "MS.AAD.4.4v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}