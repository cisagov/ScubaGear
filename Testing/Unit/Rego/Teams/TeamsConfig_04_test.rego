package teams_test
import future.keywords
import data.teams
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


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

    CorrectTestResult("MS.TEAMS.4.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.TEAMS.4.1v1", Output, PASS) == true
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

    IncorrectTestResult("MS.TEAMS.4.1v1", Output, FAIL) == true
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

    IncorrectTestResult("MS.TEAMS.4.1v1", Output, FAIL) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
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
    CorrectTestResult("MS.TEAMS.4.1v1", Output, ReportDetailString) == true
}
#--