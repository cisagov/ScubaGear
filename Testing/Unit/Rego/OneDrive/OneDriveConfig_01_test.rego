package onedrive
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--
test_OneDriveLoopSharingCapability_Correct if {
    PolicyId := "MS.ONEDRIVE.1.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 1
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneDriveLoopSharingCapability_Incorrect if {
    PolicyId := "MS.ONEDRIVE.1.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2
            }
        ],
        "OneDrive_PnP_Flag": false 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_UsingServicePrincipal if {
    PolicyId := "MS.ONEDRIVE.1.1v1"

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