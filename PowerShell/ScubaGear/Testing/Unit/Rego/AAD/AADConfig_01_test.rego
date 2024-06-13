package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult


#
# Policy MS.AAD.1.1v1
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsIncludeApplications_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsIncludeUsers_Incorrect if {
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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsExcludeUsers_Incorrect if {
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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsExcludeGroups_Incorrect if {
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
                        ]
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsClientAppTypes_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        ""
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsBuiltInControls_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": null
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_NoExclusionsState_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "disabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

# tests for user exclusions and no group exclusions
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsConditions_Correct if {
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
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
                            "df269963-a081-4315-b7de-172755221504"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
                    "CapExclusions": {
                        "Users": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "df269963-a081-4315-b7de-172755221504"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
}

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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                            "df269963-a081-4315-b7de-172755221504"
                        ],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                            "df269963-a081-4315-b7de-172755221504"
                        ],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsIncludeApplications_Incorrect if {
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
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsIncludeUsers_Incorrect if {
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
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeUsers": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"
                        ],
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsExcludeGroups_Incorrect if {
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
                        ]
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsClientAppTypes_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        ""
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsBuiltInControls_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
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
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsState_Incorrect if {
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
                        "ExcludeGroups": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "disabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

# tests for group exclusions and no user exclusions
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
}

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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
                    "CapExclusions": {
                        "Users": [],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionConditions_Correct if {
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
}

# tests when both group and user exclusions present
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, true) == true
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
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
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "df269963-a081-4315-b7de-172755221504"
                        ],
                        "ExcludeGroups": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeRoles": []
                    },
                    "ClientAppTypes": [
                        "other",
                        "exchangeActiveSync"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.1.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.1.1v1", Output, ReportDetailStr, false) == true
}
#--