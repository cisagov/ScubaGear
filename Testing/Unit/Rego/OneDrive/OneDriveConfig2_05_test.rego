package onedrive
import future.keywords


#
# Policy 1
#--
test_BlockMacSync_Correct if {
    ControlNumber := "OneDrive 2.5"
    Requirement := "OneDrive Client Sync SHALL only be allowed only within the local domain"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "BlockMacSync" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BlockMacSync_Incorrect if {
    ControlNumber := "OneDrive 2.5"
    Requirement := "OneDrive Client Sync SHALL only be allowed only within the local domain"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "BlockMacSync" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
