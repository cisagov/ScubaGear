package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.3.1v1
#--
test_SharingCapability_Anyone_LinkExpirationValid_Correct_V1 if {
    # Test if the Sharepoint external sharing slider is set to "Anyone".
    # If true, then evaluate the value for expiration days.
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2,
                "RequireAnonymousLinksExpireInDays": 30
            }
        ]
    }

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_SharingCapability_Anyone_LinkExpirationValid_Correct_V2 if {
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

test_SharingCapability_Anyone_LinkExpirationInvalid_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    ReportDetailsString := concat(" ", [
        "Requirement not met:",
        "External Sharing is set to Anyone and expiration date is not set to 30 days or less."
    ])
    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailsString, false) == true
}

test_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    # Test if the Sharepoint external sharing slider is set to "Only people in your organization".
    # The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    PolicyId := "MS.SHAREPOINT.3.1v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Only people in your organization.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_SharingCapability_ExistingGuests_NotApplicable if {
    # Test if the Sharepoint external sharing slider is set to "Existing guests".
    # The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    PolicyId := "MS.SHAREPOINT.3.1v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Existing guests.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_SharingCapability_NewExistingGuests_NotApplicable if {
    # Test if the Sharepoint external sharing slider is set to "New and existing guests".
    # The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    PolicyId := "MS.SHAREPOINT.3.1v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to New and existing guests.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}
#--

#
# Policy MS.SHAREPOINT.3.2v1
#--
test_File_Folder_AnonymousLinkType_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 1,
                "FolderAnonymousLinkType": 1,
                "SharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    TestResult("MS.SHAREPOINT.3.2v1", Output, PASS, true) == true
}

test_File_Folder_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 2,
                "SharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: both files and folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_Folder_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 1,
                "FolderAnonymousLinkType": 2,
                "SharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_File_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 1,
                "SharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    ReportDetailString := "Requirement not met: files are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailString, false) == true
}

test_AnonymousLinkType_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 1,
                "SharingCapability": 2
            }
        ],
        "OneDrive_PnP_Flag": true
    }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 2,
                "SharingCapability": 0
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    PolicyId := "MS.SHAREPOINT.3.2v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Only people in your organization.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_ExistingGuests_NotApplicable if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 2,
                "SharingCapability": 3
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    PolicyId := "MS.SHAREPOINT.3.2v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Existing guests.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_NewExistingGuests_NotApplicable if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType": 2,
                "FolderAnonymousLinkType": 2,
                "SharingCapability": 1
            }
        ],
        "OneDrive_PnP_Flag": false
    }

    PolicyId := "MS.SHAREPOINT.3.2v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to New and existing guests.",
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

#
# Policy MS.SHAREPOINT.3.3v1
#--
test_EmailAttestationReAuthDays_SharingCapability_NewExistingGuests_Correct if {
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

test_EmailAttestationReAuthDays_SharingCapability_Anyone_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2,
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

test_EmailAttestationReAuthDays_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": false,
                "EmailAttestationReAuthDays": 31
            }
        ]
    }

    ReportDetailsString :=
        "Requirement not met: Expiration time for 'People who use a verification code' NOT enabled and set to 30 days or more"

    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailsString, false) == true
}

test_EmailAttestationReAuthDays_Incorrect_V2 if {
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
        "Requirement not met: Expiration time for 'People who use a verification code' NOT set to 30 days or less"

    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString, false) == true
}

test_EmailAttestationRequired_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1,
                "EmailAttestationRequired": false,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    ReportDetailString := "Requirement not met: Expiration time for 'People who use a verification code' NOT enabled"
    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailString, false) == true
}

test_EmailAttestationReAuthDays_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    PolicyId := "MS.SHAREPOINT.3.3v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Only people in your organization.",
        "This policy is only applicable if External Sharing is set to Anyone or New and existing guests. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_EmailAttestationReAuthDays_SharingCapability_ExistingGuests_NotApplicable if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3,
                "EmailAttestationRequired": true,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    PolicyId := "MS.SHAREPOINT.3.3v1"
    ReportDetailsString := concat(" ", [
        "External Sharing is set to Existing guests.",
        "This policy is only applicable if External Sharing is set to Anyone or New and existing guests. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}
#--