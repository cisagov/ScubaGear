package onedrive
import future.keywords


#
# Policy 1
#--
test_AllowedDomainList_Correct if {
    ControlNumber := "OneDrive 2.4"
    Requirement := "OneDrive Client for Windows SHALL be restricted to agency-Defined Domain(s)"

    Output := tests with input as {
        "Expected_results": {
            "Owner" : "c64580cf-5b99-4c0a-b15b-db035c63e177"
        },
        "Tenant_sync_info": {
            "AllowedDomainList": [
                "786548dd-877b-4760-a749-6b1efbc1190a",
                "877564ff-877b-4760-a749-6b1efbc1190a",
                "c64580cf-5b99-4c0a-b15b-db035c63e177"
            ]
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomainList_Incorrect if {
    ControlNumber := "OneDrive 2.4"
    Requirement := "OneDrive Client for Windows SHALL be restricted to agency-Defined Domain(s)"

    Output := tests with input as {
        "Expected_results": {
            "Owner" : "c64580cf-5b99-4c0a-b15b-db035c63e177"
        },
        "Tenant_sync_info": {
            "AllowedDomainList": [
                "786548dd-877b-4760-a749-6b1efbc1190a",
                "877564ff-877b-4760-a749-6b1efbc1190a"
            ]
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}