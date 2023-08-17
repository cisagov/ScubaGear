package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails

#
# MS.SHAREPOINT.3.1v1
#--
test_ExternalUserExpireInDays_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0,
                "RequireAnonymousLinksExpireInDays": 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 3,
                "RequireAnonymousLinksExpireInDays": 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Correct_V3 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "RequireAnonymousLinksExpireInDays": 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Correct_V4 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays": 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Incorrect if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: External Sharing is set to New and Existing Guests and expiration date is not 30 days or less"
}

test_ExternalUserExpireInDays_Incorrect_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays": 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: External Sharing is set to Anyone and expiration date is not 30 days or less"
}
#--

#
# MS.SHAREPOINT.3.2v1
#--
test_AnonymousLinkType_Correct if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AnonymousLinkType_Incorrect_V1 if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 2
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: both files and folders are not limited to view for Anyone"
}

test_AnonymousLinkType_Incorrect_V2 if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 2
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: folders are not limited to view for Anyone"
}

test_AnonymousLinkType_Incorrect_V3 if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 1
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: files are not limited to view for Anyone"
}

test_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 1
            }
        ],
        "OneDrive_PnP_Flag": true   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# MS.SHAREPOINT.3.3v1
#--
test_SharingCapability_Correct if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0,
                "EmailAttestationRequired" : true,
                "EmailAttestationReAuthDays": 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Correct_V4 if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "EmailAttestationRequired" : true,
                "EmailAttestationReAuthDays": 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EmailAttestationReAuthDays_Correct if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "EmailAttestationRequired" : true,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Multi_Incorrect_V1 if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "EmailAttestationRequired" : false,
                "EmailAttestationReAuthDays": 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled and set to greater 30 days"
}

test_EmailAttestationRequired_Incorrect_V2 if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "EmailAttestationRequired" : false,
                "EmailAttestationReAuthDays": 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled"
}

test_EmailAttestationReAuthDays_Incorrect_V3 if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "EmailAttestationRequired" : true,
                "EmailAttestationReAuthDays": 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"
}
#--
