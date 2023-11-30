package sharepoint_test
import future.keywords
import data.sharepoint


#
# MS.SHAREPOINT.2.1v1
#--
test_DefaultSharingLinkType_Correct if {
    PolicyId := "MS.SHAREPOINT.2.1v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultSharingLinkType_Incorrect if {
    PolicyId := "MS.SHAREPOINT.2.1v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.SHAREPOINT.2.2v1
#--
test_DefaultLinkPermission_Correct if {
    PolicyId := "MS.SHAREPOINT.2.2v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission" : 1
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultLinkPermission_Incorrect if {
    PolicyId := "MS.SHAREPOINT.2.2v1"

    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission" : 2
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--