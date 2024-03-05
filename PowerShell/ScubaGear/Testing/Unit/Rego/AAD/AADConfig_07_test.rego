package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.AAD.7.1v1
#--
test_PrivilegedUsers_Correct if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := "2 global admin(s) found:<br/>Test Name1, Test Name2"
    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, true) == true
}

test_PrivilegedUsers_Incorrect_V1 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := "1 global admin(s) found:<br/>Test Name1"
    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, false) == true
}

test_PrivilegedUsers_Incorrect_V2 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name3",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User4": {
                "DisplayName": "Test Name4",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User5": {
                "DisplayName": "Test Name5",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User6": {
                "DisplayName": "Test Name6",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User7": {
                "DisplayName": "Test Name7",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User8": {
                "DisplayName": "Test Name8",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User9": {
                "DisplayName": "Test Name9",
                "roles": [
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := concat(" ", [
        "9 global admin(s) found:<br/>Test Name1, Test Name2, Test Name3,",
        "Test Name4, Test Name5, Test Name6, Test Name7, Test Name8, Test Name9"
    ])

    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, false) == true
}
#--

#--
# Policy MS.AAD.7.2v1
#--
# Correct because the ratio of global admins to non global admins is less than 1
test_SecureScore_Correct_V1 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Cloud Application Administrator",
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name3",
                "roles": [
                    "Application Administrator"
                ]
            },
            "User4": {
                "DisplayName": "Test Name4",
                "roles": [
                    "User Administrator"
                ]
            },
            "User5": {
                "DisplayName": "Test Name5",
                "roles": [
                    "Privileged Role Administrator"
                ]
            }
        }
    }

    ReportDetailStr := "Requirement met: Least Privilege Score = 0.66 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, true) == true
}

# Correct because the ratio of global admins to non global admins is equal to 1
test_SecureScore_Incorrect_V1 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "User Administrator",
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name3",
                "roles": [
                    "Application Administrator"
                ]
            },
            "User4": {
                "DisplayName": "Test Name4",
                "roles": [
                    "Privileged Role Administrator"
                ]
            }
        }
    }

    ReportDetailStr := "Requirement met: Least Privilege Score = 1 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, true) == true
}

# Incorrect because the ratio of global admins to non global admins is more than 1
test_SecureScore_Incorrect_V2 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "User Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Application Administrator",
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Privileged Role Administrator"
                ]
            }
        }
    }

    ReportDetailStr := "Requirement not met: Least Privilege Score = 2 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

# Incorrect because the ratio of global admins to non global admins is undefined (all are global admins)
test_SecureScore_Incorrect_V3 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "User Administrator",
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Hybrid Identity Administrator",
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailStr := "Requirement not met: All privileged users are Global Admin"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

# Incorrect because the total number of global admins is greater than eight
test_SecureScore_Incorrect_V4 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Test Name1",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Test Name2",
                "roles": [
                    "Exchange Administrator",
                    "Global Administrator"
                ]
            },
            "User3": {
                "DisplayName": "Test Name3",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User4": {
                "DisplayName": "Test Name4",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User5": {
                "DisplayName": "Test Name5",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User6": {
                "DisplayName": "Test Name6",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User7": {
                "DisplayName": "Test Name7",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User8": {
                "DisplayName": "Test Name8",
                "roles": [
                    "Global Administrator"
                ]
            },
            "User9": {
                "DisplayName": "Test Name9",
                "roles": [
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailStr := "Requirement not met: Policy MS.AAD.7.1 failed so score not computed"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

#--
# Policy MS.AAD.7.3v1
#--
test_OnPremisesImmutableId_Correct if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Alice",
                "OnPremisesImmutableId": null,
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Bob",
                "OnPremisesImmutableId": null,
                "roles": [
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := "0 admin(s) that are not cloud-only found"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, true) == true
}

test_OnPremisesImmutableId_Incorrect_V1 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Alice",
                "OnPremisesImmutableId": "HelloWorld",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := "1 admin(s) that are not cloud-only found:<br/>Alice"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, false) == true
}

test_OnPremisesImmutableId_Incorrect_V2 if {
    Output := aad.tests with input as {
        "privileged_users": {
            "User1": {
                "DisplayName": "Alice",
                "OnPremisesImmutableId": "HelloWorld",
                "roles": [
                    "Privileged Role Administrator",
                    "Global Administrator"
                ]
            },
            "User2": {
                "DisplayName": "Bob",
                "OnPremisesImmutableId": null,
                "roles": [
                    "Global Administrator"
                ]
            }
        }
    }

    ReportDetailString := "1 admin(s) that are not cloud-only found:<br/>Alice"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, false) == true
}
#--

# Policy MS.AAD.7.4v1
#--
test_AdditionalProperties_Correct_V1 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Correct_V2 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Correct_V3 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_LicenseMissing_V1 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
            }
        ],
        "scuba_config": {
            "Aad": {
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString :=
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V1 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V2 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V3 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V4 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    },
                    {
                        "EndDateTime": null,
                        "PrincipalId": "38035edd-63a1-4c08-8bd2-ad78d0624057"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V5 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V6 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V7 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V8 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    },
                    {
                        "EndDateTime": null,
                        "PrincipalId": "38035edd-63a1-4c08-8bd2-ad78d0624057"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V9 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [
                            "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                        ],
                        "Groups": []
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V10 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V11 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V12 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V13 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    },
                    {
                        "EndDateTime": null,
                        "PrincipalId": "38035edd-63a1-4c08-8bd2-ad78d0624057"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "7b36d094-0211-400b-aabd-3793e9a30fc6"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V14 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "EndDateTime": null,
                        "PrincipalId": "ae71e61c-f465-4db6-8d26-5f3e52bdd800"
                    }
                ]
            },
            {
                "DisplayName": "Application Administrator",
                "Assignments": [
                    {
                        "EndDateTime": "/Date(1691006065170)/",
                        "PrincipalId": "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                    }
                ]
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
                "MS.AAD.7.4v1": {
                    "RoleExclusions": {
                        "Users": [],
                        "Groups": [
                            "e54ac846-1f5a-4afe-aa69-273b42c3b0c1"
                        ]
                    }
                }
            }
        }
    }

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.5v1
#--
test_Assignments_Correct if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "StartDateTime": "/Date(1660328610000)/"
                    }
                ],
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P30D"
                        }
                    }
                ]
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

    ReportDetailString := "0 role(s) assigned to users outside of PIM"
    TestResult("MS.AAD.7.5v1", Output, ReportDetailString, true) == true
}

test_Assignments_Incorrect if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Assignments": [
                    {
                        "StartDateTime": null
                    }
                ],
                "Rules": [
                    {
                        "Id": "Expiration_Admin_Assignment",
                        "AdditionalProperties": {
                            "isExpirationRequired": true,
                            "maximumDuration": "P30D"
                        }
                    }
                ]
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

    ReportDetailString := "1 role(s) assigned to users outside of PIM:<br/>Global Administrator"
    TestResult("MS.AAD.7.5v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.6v1
#--
test_AdditionalProperties_Correct_V4 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Approval_EndUser_Assignment",
                        "AdditionalProperties": {
                            "setting": {
                                "isApprovalRequired": true
                            }
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.6v1", Output, PASS, true) == true
}

test_AdditionalProperties_Correct_V5 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Approval_EndUser_Assignment",
                        "AdditionalProperties": {
                            "setting": {
                                "isApprovalRequired": true
                            }
                        }
                    }
                ]
            },
            {
                "DisplayName": "Groups Administrator",
                "Rules": [
                    {
                        "Id": "Approval_EndUser_Assignment",
                        "AdditionalProperties": {
                            "setting": {
                                "isApprovalRequired": false
                            }
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.6v1", Output, PASS, true) == true
}

test_AdditionalProperties_Incorrect_V15 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Approval_EndUser_Assignment",
                        "AdditionalProperties": {
                            "setting": {
                                "isApprovalRequired": false
                            }
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.6v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.AAD.7.7v1
#--
test_notificationRecipients_Correct if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties": {
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    },
                    {
                        "Id": "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties": {
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    }
                ]
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

    ReportDetailString := "0 role(s) without notification e-mail configured for role assignments found"
    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, true) == true
}

test_notificationRecipients_Incorrect_V1 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties": {
                            "notificationRecipients": []
                        }
                    },
                    {
                        "Id": "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties": {
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    }
                ]
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

    ReportDetailString :=
        "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}

test_notificationRecipients_Incorrect_V2 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties": {
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    },
                    {
                        "Id": "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties": {
                            "notificationRecipients": []
                        }
                    }
                ]
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

    ReportDetailString :=
        "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}

test_notificationRecipients_Incorrect_V3 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties": {
                            "notificationRecipients": []
                        }
                    },
                    {
                        "Id": "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties": {
                            "notificationRecipients": []
                        }
                    }
                ]
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

    ReportDetailString :=
        "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.8v1
#--
test_Id_Correct_V1 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties": {
                            "notificationType": "Email",
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.8v1", Output, PASS, true) == true
}

test_Id_Correct_V2 if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties": {
                            "notificationType": "",
                            "notificationRecipients": [
                                "test@example.com"
                            ]
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.8v1", Output, PASS, true) == true
}

test_Id_Incorrect if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties": {
                            "notificationType": "Email",
                            "notificationRecipients": []
                        }
                    }
                ]
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

    TestResult("MS.AAD.7.8v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.AAD.7.9v1
#--

test_DisplayName_Correct if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties": {
                            "notificationType": "Email",
                            "notificationRecipients": []
                        }
                    }
                ]
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

    ReportDetailString := "0 role(s) without notification e-mail configured for role activations found"
    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, true) == true
}

test_DisplayName_Incorrect if {
    Output := aad.tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Cloud Administrator",
                "Rules": [
                    {
                        "Id": "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties": {
                            "notificationType": "Email",
                            "notificationRecipients": []
                        }
                    }
                ]
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

    ReportDetailString :=
        "1 role(s) without notification e-mail configured for role activations found:<br/>Cloud Administrator"
    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, false) == true
}
#--