package sharepoint_test
import future.keywords
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# MS.SHAREPOINT.1.1v1
#--
test_SharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.1.1v1", Output, PASS) == true
}

test_SharingCapability_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.1.1v1", Output, PASS) == true
}

test_SharingCapability_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.1.1v1", Output, FAIL) == true
}

test_SharingCapability_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.1.1v1", Output, FAIL) == true
}
#--

#
# MS.SHAREPOINT.1.2v1
#--
test_OneDriveSharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability": 0
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    CorrectTestResult("MS.SHAREPOINT.1.2v1", Output, PASS) == true
}

test_OneDriveSharingCapability_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability": 3
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    CorrectTestResult("MS.SHAREPOINT.1.2v1", Output, PASS) == true
}

test_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability": 3
            }
        ],
        "OneDrive_PnP_Flag": true
    }

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}

test_OneDriveSharingCapability_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability": 1
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    IncorrectTestResult("MS.SHAREPOINT.1.2v1", Output, FAIL) == true
}

test_OneDriveSharingCapability_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    IncorrectTestResult("MS.SHAREPOINT.1.2v1", Output, FAIL) == true
}
#--

#
# MS.SHAREPOINT.1.3v1
#--
test_SharingDomainRestrictionMode_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "SharingDomainRestrictionMode": 0
            }
        ]
    }

    ReportDetailString := "Requirement met: external sharing is set to Only People In Organization"
    CorrectTestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString) == true
}

test_SharingDomainRestrictionMode_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "SharingDomainRestrictionMode": 1
            }
        ]
    }

    ReportDetailString := concat(" ", [
        "Requirement met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    CorrectTestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString) == true
}

test_SharingDomainRestrictionMode_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "SharingDomainRestrictionMode": 0
            }
        ]
    }

    ReportDetailString := concat(" ", [
        "Requirement not met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    IncorrectTestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString) == true
}
#--

#
# MS.SHAREPOINT.1.4v1
#--
test_SameAccount_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "RequireAcceptingAccountMatchInvitedAccount": false
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.1.4v1", Output, PASS) == true
}

test_SameAccount_Correct_V3 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "RequireAcceptingAccountMatchInvitedAccount": true
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.1.4v1", Output, PASS) == true
}

test_SameAccount_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "RequireAcceptingAccountMatchInvitedAccount": true
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.1.4v1", Output, PASS) == true
}

test_SameAccount_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "RequireAcceptingAccountMatchInvitedAccount": false
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.1.4v1", Output, FAIL) == true
}
#--