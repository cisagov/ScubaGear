package sharepoint
import future.keywords


#
# Policy 1
#--
test_SharingCapability_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.1.3v1"
 
    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}