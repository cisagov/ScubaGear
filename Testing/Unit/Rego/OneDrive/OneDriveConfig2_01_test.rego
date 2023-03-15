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
                "OneDriveSharingCapability" : 1
            }
        ],
        "OneDrive_PnP_Flag": false   
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
                "OneDriveSharingCapability" : 2
            }
        ],
        "OneDrive_PnP_Flag": false 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_UsingServicePrincipal if {
    ControlNumber := "OneDrive 2.1"
    Requirement := "Anyone links SHOULD be disabled"

    Output := tests with input as {
        "SPO_tenant_info": [
        ],
        "OneDrive_PnP_Flag": true 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically while using Service Principals. See Onedrive Secure Configuration Baseline policy 2.1 for instructions on manual check"
}