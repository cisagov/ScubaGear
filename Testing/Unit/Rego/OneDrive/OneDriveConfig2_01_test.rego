package onedrive
import future.keywords


#
# Policy 1
#--
test_OneDriveLoopSharingCapability_Correct if {
    ControlNumber := "OneDrive 2.1"
    Requirement := "Anyone links SHOULD be disabled"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 1
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneDriveLoopSharingCapability_Incorrect if {
    ControlNumber := "OneDrive 2.1"
    Requirement := "Anyone links SHOULD be disabled"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 2
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
