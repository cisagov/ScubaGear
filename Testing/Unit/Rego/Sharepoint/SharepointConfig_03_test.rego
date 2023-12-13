package sharepoint_test
import future.keywords
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.PASS


#
# MS.SHAREPOINT.3.1v1
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

    CorrectTestResult("MS.SHAREPOINT.3.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.SHAREPOINT.3.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.SHAREPOINT.3.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.SHAREPOINT.3.1v1", Output, PASS) == true
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

    ReportDetailString := "Requirement not met: External Sharing is set to New and Existing Guests and expiration date is not 30 days or less"
    IncorrectTestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailString) == true
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

    ReportDetailString := "Requirement not met: External Sharing is set to Anyone and expiration date is not 30 days or less"
    IncorrectTestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailString) == true
}
#--

#
# MS.SHAREPOINT.3.2v1
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

    CorrectTestResult("MS.SHAREPOINT.3.2v1", Output, PASS) == true
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
    IncorrectTestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString) == true
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
    IncorrectTestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString) == true
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
    IncorrectTestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString) == true
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

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}

#
# MS.SHAREPOINT.3.3v1
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

    CorrectTestResult("MS.SHAREPOINT.3.3v1", Output, PASS) == true
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

    CorrectTestResult("MS.SHAREPOINT.3.3v1", Output, PASS) == true
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

    CorrectTestResult("MS.SHAREPOINT.3.3v1", Output, PASS) == true
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

    ReportDetailString := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled and set to >30 days"
    IncorrectTestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString) == true
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
    IncorrectTestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString) == true
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

    ReportDetailString := "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"
    IncorrectTestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString) == true
}
#--