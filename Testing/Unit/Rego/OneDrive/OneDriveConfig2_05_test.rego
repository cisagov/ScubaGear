package onedrive
import future.keywords


#
# Policy 1
#--
test_BlockMacSync_Correct if {
    PolicyId := "MS.ONEDRIVE.2.3v1"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "BlockMacSync" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BlockMacSync_Incorrect if {
    PolicyId := "MS.ONEDRIVE.2.3v1"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "BlockMacSync" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
