package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.TEAMS.4.1v1
#--
test_AllowEmailIntoChannel_Correct_V1 if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": false
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams",
                    "MCOProfessional"
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Correct_V1_multi if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": false
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams",
                    "MCOProfessional"
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Incorrect if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams",
                    "MCOProfessional"
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Incorrect_multi if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams",
                    "MCOProfessional"
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Correct_V2 if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": false
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams_GCC",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V2_multi if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": false
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "TEAMS_GCCHIGH",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V3 if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams_GCC",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V3_multi if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams_GCC",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V4 if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "TEAMS_GCCHIGH",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V4_multi if {
    Output := teams.tests with input as {
        "client_configuration": [
            {
                "Identity": "Global",
                "AllowEmailIntoChannel": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowEmailIntoChannel": true
            }
        ],
        "teams_tenant_info": [
            {
                "AssignedPlan": [
                    "MCOEV",
                    "Teams_GCCHIGH",
                    "MCOProfessional"
                ]
            }
        ]
    }

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}
#--