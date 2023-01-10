package onedrive
import future.keywords


#
# Policy 1
#--
test_DefaultLinkPermission_Correct if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "DefaultLinkPermission" : 1,
                "OneDriveSharingCapability":  1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultLinkPermission_Incorrect if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "DefaultLinkPermission" : 2,
                "OneDriveSharingCapability":  1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_DefaultLinkPermission_Incorrect_V2 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "DefaultLinkPermission" : 1,
                "OneDriveSharingCapability":  2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
