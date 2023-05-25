package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--
test_NotImplemented_Correct if {
    ControlNumber := "Sharepoint 2.5"
    PolicyId := "MS.SHAREPOINT.TBD"
    Requirement := "Users SHALL be prevented from running custom scripts on personal sites (OneDrive)"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 2
#--
test_DenyAddAndCustomizePages_Correct if {
    ControlNumber := "Sharepoint 2.5"
    Requirement := "Users SHALL be prevented from running custom scripts on self-service created sites"

    Output := tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages" : 2
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DenyAddAndCustomizePages_Incorrect if {
    ControlNumber := "Sharepoint 2.5"
    Requirement := "Users SHALL be prevented from running custom scripts on self-service created sites"

    Output := tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
