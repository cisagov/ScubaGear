package aad
import future.keywords


#
# Policy 1
#--tests for no exclusions
test_NoExclusionsConditions_Correct if {
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
                        "ExcludeGroups": []
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

test_NoExclusionsIncludeApplications_Incorrect if {
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
                        "ExcludeGroups": [],
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

test_NoExclusionsIncludeUsers_Incorrect if {
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
                        "ExcludeGroups": [],
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

test_NoExclusionsExcludeUsers_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],

    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExcludeGroups_Incorrect if {
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
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
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


test_NoExclusionsClientAppTypes_Incorrect if {
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
                        "ExcludeGroups": [],
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

test_NoExclusionsBuiltInControls_Incorrect if {
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
                        "ExcludeGroups": [],
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

test_NoExclusionsState_Incorrect if {
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
                        "ExcludeGroups": [],
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

#--tests for user exclusions and no group exclusions
test_UserExclusionsConditions_Correct if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsIncludeApplications_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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

test_UserExclusionsIncludeUsers_Incorrect if {
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
                        "IncludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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

test_UserExclusionsExcludeUsers_Incorrect if {
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
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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

test_UserExclusionsExcludeGroups_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {

            "Aad": {
                 "Policy2_1": {
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


test_UserExclusionsClientAppTypes_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": [""]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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

test_UserExclusionsBuiltInControls_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": null
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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

test_UserExclusionsState_Incorrect if {
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
                        "ExcludeUsers": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups": [],
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "disabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                 "Policy2_1": {
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