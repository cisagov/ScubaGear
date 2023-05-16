package onedrive
import future.keywords
import data.report.utils.notCheckedDetails

#
# Policy 1
#--
test_ExternalUserExpirationRequired_Correct_V1 if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 1,
                "RequireAnonymousLinksExpireInDays" : 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_ExternalUserExpirationRequired_Correct_V2 if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpirationRequired_Incorrect if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration date is not 30"
}

test_UsingServicePrincipal if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "SPO_tenant_info": [
        ],
        "OneDrive_PnP_Flag": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == notCheckedDetails(PolicyId)
}

test_UsingServicePrincipal if {
    PolicyId := "MS.ONEDRIVE.2.2v1"

    Output := tests with input as {
        "SPO_tenant_info": [
        ],
        "OneDrive_PnP_Flag": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == notCheckedDetails(PolicyId)
}