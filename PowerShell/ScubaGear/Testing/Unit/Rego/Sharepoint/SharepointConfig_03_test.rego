package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.3.1v1
#--
test_ExternalUserExpireInDays_Correct_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "RequireAnonymousLinksExpireInDays": 30
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_ExternalUserExpireInDays_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3,
                "RequireAnonymousLinksExpireInDays": 30
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_ExternalUserExpireInDays_Correct_V3 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "RequireAnonymousLinksExpireInDays": 29
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_ExternalUserExpireInDays_Correct_V4 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2,
                "RequireAnonymousLinksExpireInDays": 29
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_ExternalUserExpireInDays_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    ReportDetailString := concat(" ", [
        "Requirement not met: External Sharing is set to New",
        "and Existing Guests and expiration date is not 30 days or less"
    ])
    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailString, false) == true
}

test_ExternalUserExpireInDays_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    ReportDetailString :=
        "Requirement not met: External Sharing is set to Anyone and expiration date is not 30 days or less"

    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SHAREPOINT.3.2v1
#--
test_AnonymousLinkType_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 1,
                "FolderAnonymousLinkType": 1
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    TestResult("MS.SHAREPOINT.3.2v1", Output, PASS, true) == true
}

test_AnonymousLinkType_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: both files and folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_AnonymousLinkType_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 1,
                "FolderAnonymousLinkType": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_AnonymousLinkType_Incorrect_V3 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 1
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: files are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 1
            }
        ],
        "OneDrive_PnP_Flag": true
    }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}

#
# Policy MS.SHAREPOINT.3.3v1
#--
test_SharingCapability_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 30
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_SharingCapability_Correct_V4 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 30
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_EmailAttestationReAuthDays_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_Multi_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": false,
                "EmailAttestationReAuthDays": 31
            }
        ]
    }

    ReportDetailString :=
        "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled and set to >30 days"

    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString, false) == true
}

test_EmailAttestationRequired_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": false,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    ReportDetailString := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled"
    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString, false) == true
}

test_EmailAttestationReAuthDays_Incorrect_V3 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 31
            }
        ]
    }

    ReportDetailString :=
        "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"

    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString, false) == true
}
#--