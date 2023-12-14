package aad_test
import future.keywords
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.policy.TestResult
import data.utils.policy.TestResultContains
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# MS.AAD.3.1v1
#--
test_PhishingResistantAllMFA_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, true) == true
}

test_PhishingResistantSingleMFA_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, true) == true
}

test_PhishingResistantExtraMFA_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "x509CertificateMultiFactor",
                            "SuperStrength"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, false) == true
}

test_PhishingResistantNoneMFA_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": null
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, false) == true
}

test_PhishingResistantMFAExcludeApp_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": [
                            "Some App"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, false) == true
}

test_PhishingResistantMFAExcludeUser_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "me"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, false) == true
}

test_PhishingResistantMFAExcludeGroup_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "some"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.2v1
#--
test_NoExclusionsConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_3_1_Passes_3_2_Fails_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            },
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        ""
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_3_1_Fails_3_2_Passes_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor",
                            "SuperStrength"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test name"
            },
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_NoExclusionsExemptUsers_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_NoExclusionsExemptGroups_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_UserExclusionConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_UserExclusionsNoExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_UserExclusionsSingleExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_MultiUserExclusionsConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_GroupExclusionsConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_GroupExclusionsNoExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_MultiGroupExclusionsConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test name"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.2v1": {
                    "CapExclusions": {
                        "Users": [
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ],
                        "Groups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

# Other conditions
test_ConditionalAccessPolicies_Correct_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy require MFA for All Users. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, true) == true
}

test_IncludeApplications_Incorrect_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "Office365"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users, but not all Apps"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_IncludeUsers_Incorrect_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_ExcludeUsers_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_ExcludeGroups_Incorrect if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [
                            "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_ExcludeRoles_Incorrect_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": [
                            "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_BuiltInControls_Incorrect_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        ""
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test Policy does not require MFA"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}

test_State_Incorrect_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "mfa"
                    ]
                },
                "State": "disabled",
                "DisplayName": "Test Policy is correct, but not enabled"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.3v1
#--
test_3_1_passes_and_satisfies_3_3 if{
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "Test Policy"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.3v1", Output, ReportDetailString, true) == true
}

test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.AAD.3.3v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.4v1
#--
test_Migrated_Correct if {
    Output := aad.tests with input as {
        "authentication_method": [
            {
                "PolicyMigrationState": "migrationComplete"
            }
        ]
    }

    TestResult("MS.AAD.3.4v1", Output, PASS, true) == true
}

test_Migrated_Incorrect if {
    Output := aad.tests with input as {
        "authentication_method": [
            {
                "PolicyMigrationState": "preMigration"
            }
        ]
    }

    TestResult("MS.AAD.3.4v1", Output, FAIL, false) == true
}
#--

#
# MS.AAD.3.5v1
#--
test_NotImplemented_Correct_V4 if {
    PolicyId := "MS.AAD.3.5v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.6v1
#--
test_ConditionalAccessPolicies_Correct_all_strengths if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, true) == true
}

test_ConditionalAccessPolicies_Correct_windowsHelloForBusiness_only if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, true) == true
}

test_ConditionalAccessPolicies_Correct_fido2_only if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "fido2"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, true) == true
}

test_ConditionalAccessPolicies_Correct_x509_only if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, true) == true
}

test_ConditionalAccessPolicies_Incorrect_not_all_apps if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}

test_BuiltInControls_Incorrect_No_Authentication_Strenght if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": null
                    },
                    "BuiltInControls": [
                        ""
                    ]
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}

test_ConditionalAccessPolicies_Incorrect_disabled if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "disabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}

test_ConditionalAccessPolicies_Incorrect_Covered_Roles if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}

test_ConditionalAccessPolicies_Incorrect_Wrong_Roles if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1"
                        ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}

test_ExcludeRoles_Incorrect_V2 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "ExcludeApplications": []
                    },
                    "Users": {
                        "IncludeRoles": [
                            "Role1",
                            "Role2"
                        ],
                        "ExcludeRoles": [
                            "Role1"
                        ]
                    }
                },
                "GrantControls": {
                    "AuthenticationStrength": {
                        "AllowedCombinations": [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.7v1
#--
test_ConditionalAccessPolicies_Correct_V3 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, true) == true
}

test_BuiltInControls_Correct if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, true) == true
}

test_IncludeApplications_Incorrect_V3 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            ""
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, false) == true
}

test_IncludeUsers_Incorrect_V2 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            ""
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, false) == true
}

test_BuiltInControls_Incorrect_V3 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        ""
                    ]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, false) == true
}

test_State_Incorrect_V3 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice"
                    ]
                },
                "State": "disabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailString, false) == true
}
#--

#
# MS.AAD.3.8v1
#--
test_Correct_V1 if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeUserCorrect_V1 if {
    Output := aad.tests with input as {
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.8v1": {
                    "CapExclusions": {
                        "Users": [
                            "SpecialPerson"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "SpecialPerson"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeGroup_Correct_V1 if {
    Output := aad.tests with input as {
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.8v1": {
                    "CapExclusions": {
                        "Groups": [
                            "SpecialGroup"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeGroups": [
                            "SpecialGroup"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeUserIncorrect_V1 if {
    Output := aad.tests with input as {
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.8v1": {
                    "CapExclusions": {
                        "Users": [
                            "NotSpecialUser"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeUsers": [
                            "SpecialUser"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailString, false) == true
}

test_ExcludeGroupIncorrect_V1 if {
    Output := aad.tests with input as {
        "scuba_config": {
            "Aad": {
                "MS.AAD.3.8v1": {
                    "CapExclusions": {
                        "Groups": [
                            "SpecialGroup"
                        ]
                    }
                }
            }
        },
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ],
                        "ExcludeGroups": [
                            "NotSpecialGroup"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailString, false) == true
}

test_InCorrect_ReportOnly if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice",
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabledForReportingButNotEnforced",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailString, false) == true
}

test_Correct_OnlyCompliantDevice if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "compliantDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_Correct_OnlyDomainJoinedDevice if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "domainJoinedDevice"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_Incorrect_EmptyGrantControls if {
    Output := aad.tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [
                            "All"
                        ],
                        "IncludeUserActions": [
                            "urn:user:registersecurityinfo"
                        ]
                    },
                    "Users": {
                        "IncludeUsers": [
                            "All"
                        ]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": []
                },
                "State": "enabled",
                "DisplayName": "Managed Device Required for MFA Registration"
            }
        ]
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailString, false) == true
}

test_InCorrect_No_Policy if {
    Output := aad.tests with input as {
        "conditional_access_policies": []
    }

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailString, false) == true
}
#--