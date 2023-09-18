package aad
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean


#
# MS.AAD.3.1v1
#--
test_PhishingResistantAllMFA_Correct if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantSingleMFA_Correct if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantExtraMFA_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": [
                            "x509CertificateMultiFactor",
                            "SuperStrength"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantNoneMFA_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": null
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    #RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeApp_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : ["Some App"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeUser_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["me"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeGroup_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["some"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.2v1
#--
test_NoExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_3_1_Passes_3_2_Fails_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            },
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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_3_1_Fails_3_2_Passes_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor",
                            "SuperStrength"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            },
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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptUsers_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptGroups_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                        "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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

test_MultiUserExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups" : []
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
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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

test_MultiGroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
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
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["65fea286-22d3-42f9-b4ca-93a6f75817d4"],
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

# Other conditions
test_ConditionalAccessPolicies_Correct_V1 if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy require MFA for All Users. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Users, but not all Apps"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeUsers_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeGroups" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

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
                        "ExcludeRoles" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy does not require MFA"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

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
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "disabled",
                "DisplayName" : "Test Policy is correct, but not enabled"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.3v1
#--
test_3_1_passes_and_satisfies_3_3 if{
    PolicyId := "MS.AAD.3.3v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy. <a href='#caps'>View all CA policies</a>."

}

test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.AAD.3.3v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "Super strength"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.3.4v1
#--
test_Migrated_Correct if {
    PolicyId := "MS.AAD.3.4v1"

    Output := tests with input as { 
        "authentication_method": [
            {
                "PolicyMigrationState": "migrationComplete"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(true)
}

test_Migrated_Incorrect if {
    PolicyId := "MS.AAD.3.4v1"

    Output := tests with input as { 
        "authentication_method": [
            {
                "PolicyMigrationState": "preMigration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(false)
}
#--

#
# MS.AAD.3.5v1
#--
test_NotImplemented_Correct_V4 if {
    PolicyId := "MS.AAD.3.5v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.3.6v1
#--
test_ConditionalAccessPolicies_Correct_all_strengths if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Correct_windowsHelloForBusiness_only if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Correct_fido2_only if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["fido2"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Correct_x509_only if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Incorrect_not_all_apps if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : [],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_No_Authentication_Strenght if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": null
                    },
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Incorrect_disabled if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "disabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Incorrect_Covered_Roles if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ConditionalAccessPolicies_Incorrect_Wrong_Roles if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications":  []
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2"],
                        "ExcludeRoles" : ["Role1"]
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.7v1
#--
test_ConditionalAccessPolicies_Correct_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Correct if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : [""]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : [""]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "disabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.8v1
#--
test_Correct_V1 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "conditional access policy(s) found that meet(s) all requirements:")
}

test_ExcludeUserCorrect_V1 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "scuba_config" : {
            "Aad" : {
                PolicyId : {
                    "CapExclusions" : {
                        "Users": [
                            "SpecialPerson"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["SpecialPerson"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "conditional access policy(s) found that meet(s) all requirements:")
}

test_ExcludeGroupCorrect_V1 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "scuba_config" : {
            "Aad" : {
                PolicyId : {
                    "CapExclusions" : {
                        "Groups" : [
                            "SpecialGroup"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeGroups" : ["SpecialGroup"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "conditional access policy(s) found that meet(s) all requirements:")
}

test_ExcludeUserIncorrect_V1 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "scuba_config" : {
            "Aad" : {
                PolicyId : {
                    "CapExclusions" : {
                        "Users" : [
                            "NotSpecialUser"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["SpecialUser"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroupIncorrect_V1 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "scuba_config" : {
            "Aad" : {
                PolicyId : {
                    "CapExclusions" : {
                        "Groups" : [
                            "SpecialGroup"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeGroups" : ["NotSpecialGroup"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_InCorrect_ReportOnly if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice", "domainJoinedDevice"]
                },
                "State" : "enabledForReportingButNotEnforced",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_Correct_OnlyCompliantDevice if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "conditional access policy(s) found that meet(s) all requirements:")
}

test_Correct_OnlyDomainJoinedDevice if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "conditional access policy(s) found that meet(s) all requirements:")
}

test_InCorrect_EmptyGrantControls if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "IncludeUserActions" : ["urn:user:registersecurityinfo"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : []
                },
                "State" : "enabled",
                "DisplayName" : "Managed Device Required for MFA Registration"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_InCorrect_No_Policy if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as {
        "conditional_access_policies" : [
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--