package sharepoint
import future.keywords


#
# Policy 1
#--
test_DenyAddAndCustomizePages_Correct if {
    ControlNumber := "Sharepoint 2.5"
    Requirement := "Users SHALL be prevented from running custom scripts"

    Output := tests with input as {
        "SPO_site": {
            "DenyAddAndCustomizePages" : 1
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DenyAddAndCustomizePages_Incorrect if {
    ControlNumber := "Sharepoint 2.5"
    Requirement := "Users SHALL be prevented from running custom scripts"

    Output := tests with input as {
        "SPO_site": {
            "DenyAddAndCustomizePages" : 2
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}