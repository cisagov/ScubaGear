package onedrive
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean

#
# Policy 1
#--
test_DefaultLinkPermission_Correct_V1 if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 1,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_DefaultLinkPermission_Correct_V2 if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(true)
}

test_DefaultLinkPermission_Correct_V2 if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(true)
}

test_DefaultLinkPermission_Incorrect if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: both files and folders are not limited to view for Anyone"
}

test_DefaultLinkPermission_Incorrect_V2 if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: files are not limited to view for Anyone"
}

test_DefaultLinkPermission_Incorrect_V3 if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: folders are not limited to view for Anyone"
}

test_UsingServicePrincipal if {
    PolicyId := "MS.ONEDRIVE.3.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
        ],
        "OneDrive_PnP_Flag": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}