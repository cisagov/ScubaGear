package sharepoint
import future.keywords


#
# Policy 1
#--
test_DefaultSharingLinkType_Correct if {
    ControlNumber := "Sharepoint 2.1"
    Requirement := "File and folder links default sharing setting SHALL be set to \"Specific People (Only the People the User Specifies)\""

    Output := tests with input as {
        "SPO_tenant": {
            "DefaultSharingLinkType" : 1
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultSharingLinkType_Incorrect if {
    ControlNumber := "Sharepoint 2.1"
    Requirement := "File and folder links default sharing setting SHALL be set to \"Specific People (Only the People the User Specifies)\""

    Output := tests with input as {
        "SPO_tenant": {
            "DefaultSharingLinkType" : 2
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}