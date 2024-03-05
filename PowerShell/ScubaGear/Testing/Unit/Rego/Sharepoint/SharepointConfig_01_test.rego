package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.1.1v1
#--
test_SharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

test_SharingCapability_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

test_SharingCapability_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}

test_SharingCapability_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.2v1
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

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
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

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
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

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
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

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
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

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.3v1
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
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
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
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
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
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.4v1
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

    TestResult("MS.SHAREPOINT.1.4v1", Output, PASS, true) == true
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

    TestResult("MS.SHAREPOINT.1.4v1", Output, PASS, true) == true
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

    TestResult("MS.SHAREPOINT.1.4v1", Output, PASS, true) == true
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

    TestResult("MS.SHAREPOINT.1.4v1", Output, FAIL, false) == true
}
#--