package sharepoint
import future.keywords


#
# MS.SHAREPOINT.2.1v1
#--
test_DefaultSharingLinkType_Correct if {
    PolicyId := "MS.SHAREPOINT.2.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultSharingLinkType_Incorrect if {
    PolicyId := "MS.SHAREPOINT.2.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.SHAREPOINT.2.2v1
#--
test_DefaultLinkPermission_Correct if {
    PolicyId := "MS.SHAREPOINT.2.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultLinkPermission_Incorrect if {
    PolicyId := "MS.SHAREPOINT.2.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--