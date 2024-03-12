package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.2.1v1
#--
test_NoExclusionsConditions_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptUsers_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptGroups_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests #
test_GroupExclusionNoExempt_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
    "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V1 if {
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
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.1v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

# Other Conditions tests
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
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
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V1 if {
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        ""
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
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
                    },
                    "UserRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserRiskLevels_Incorrect if {
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
                    "UserRiskLevels": [
                        ""
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ServicePlans_Incorrect if {
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
                    "UserRiskLevels": [
                        ""
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.2.2v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.2.2v1"

    Output := aad.tests with input as { }

    ReportDetailStr := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.2.3v1
#--
test_NoExclusionsConditions_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptUsers_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptGroups_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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
                "MS.AAD.2.3v1": {
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

# Other Conditions
test_Conditions_Correct if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_IncludeApplications_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
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
                            "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"
                        ],
                        "ExcludeUsers": [],
                        "ExcludeGroups": [],
                        "ExcludeRoles": []
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V2 if {
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
                    },
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_SignInRiskLevels_Incorrect if {
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
                    "SignInRiskLevels": [
                        ""
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        ""
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V2 if {
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
                    "SignInRiskLevels": [
                        "high"
                    ]
                },
                "GrantControls": {
                    "BuiltInControls": [
                        "block"
                    ]
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

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}
#--