package aad
import future.keywords

#
# Policy 1
#--

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionConditions_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsNoExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiUserExclusionsConditions_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups": []
                    }
                }

            }

        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsConditions_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsNoExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsSingleExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiGroupExclusionsConditions_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    }
                }

            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionNoExempt_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ]
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups": []
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
            "State": "enabled",
            "DisplayName": "Test name"
        }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_9": {
                    "CapExclusions": {
                        "Users": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

# Other conditions
test_ConditionalAccessPolicies_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Name. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": [],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeUsers_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroups_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                        "ExcludeGroups": ["4b8dda31-c541-4e2d-aa7f-5f6e1980dc90"],
                        "ExcludeRoles": []
                    }
                },
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"],
                        "ExcludeUsers":[],
                        "ExcludeGroups": [],
                        "ExcludeRoles": ["4b8dda31-c541-4e2d-aa7f-5f6e1980dc90"]
                    }
                },
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IsEnabled_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : false,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_Type_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "Hello World",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_Value_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 24
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
            "SessionControls": {
                "SignInFrequency": {
                    "IsEnabled" : true,
                    "Type" : "hours",
                    "Value" : 12
                }
            },
                "State": "disabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}