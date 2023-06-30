package aad
import future.keywords


#
# MS.AAD.1.1v1
#--
test_NoExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsIncludeApplications_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["Office365"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsIncludeUsers_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExcludeUsers_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsClientAppTypes_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : [""]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsBuiltInControls_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : null
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsState_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "disabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

# tests for user exclusions and no group exclusions #
test_NoExclusionsExemptUsers_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_MultiUserExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "df269963-a081-4315-b7de-172755221504"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "df269963-a081-4315-b7de-172755221504"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "df269963-a081-4315-b7de-172755221504"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "df269963-a081-4315-b7de-172755221504"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : []
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

test_UserExclusionsIncludeApplications_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["Office365"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsIncludeUsers_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsClientAppTypes_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : [""]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsBuiltInControls_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : null
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

test_UserExclusionsState_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "disabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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

# tests for group exclusions and no user exclusions #
test_NoExclusionsExemptGroups_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : []
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

test_GroupExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : []
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

test_GroupExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
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

test_GroupExclusionConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_MultiGroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

# tests when both group and user exclusions present #
test_UserGroupExclusionConditions_Correct if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
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
    PolicyId := "MS.AAD.1.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "df269963-a081-4315-b7de-172755221504"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    },
                    "ClientAppTypes" : ["other", "exchangeActiveSync"]
                },
                "GrantControls" : {
                    "BuiltInControls" : ["block"]
                },
                "State" : "enabled",
                "DisplayName" : "Test block Legacy Authentication"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                 "MS.AAD.1.1v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
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
#--