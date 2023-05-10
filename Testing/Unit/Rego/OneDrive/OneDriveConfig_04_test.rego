package onedrive
import future.keywords


#
# Policy 1
#--
test_AllowedDomainList_Correct_V1 if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "AllowedDomainList": [
                    "786548dd-877b-4760-a749-6b1efbc1190a"
                ]
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomainList_Correct_V2 if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "Tenant_sync_info": [
            {
                "AllowedDomainList": [
                    "786548dd-877b-4760-a749-6b1efbc1190a",
                    "877564ff-877b-4760-a749-6b1efbc1190a",
                    "c64580cf-5b99-4c0a-b15b-db035c63e177"
                ]
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomainList_Incorrect if {
    PolicyId := "MS.ONEDRIVE.2.1v1"

    Output := tests with input as {
        "Tenant_sync_info": [
           {
                "AllowedDomainList": [ ]
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
