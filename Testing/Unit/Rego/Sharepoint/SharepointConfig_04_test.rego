package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails


#
# MS.SHAREPOINT.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.4.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    PolicyId := "MS.SHAREPOINT.4.2v1"

    Output := tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DenyAddAndCustomizePages_Incorrect if {
    PolicyId := "MS.SHAREPOINT.4.2v1"

    Output := tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--