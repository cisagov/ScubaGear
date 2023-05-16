package onedrive
import future.keywords
import data.report.utils.ReportDetailsBoolean

#
# Policy 1
#--
test_BlockMacSync_Correct if {
    PolicyId := "MS.ONEDRIVE.5.1v1"

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
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(true)
}

test_BlockMacSync_Incorrect if {
    PolicyId := "MS.ONEDRIVE.5.1v1"

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
    RuleOutput[0].ReportDetails == ReportDetailsBoolean(false)
}
