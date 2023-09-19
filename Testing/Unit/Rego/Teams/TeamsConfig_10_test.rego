package teams
import future.keywords


#
# Policy 1.7
#--
test_BroadcastRecordingMode_Correct if {
    PolicyId := "MS.TEAMS.1.7v1"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BroadcastRecordingMode_Incorrect if {
    PolicyId := "MS.TEAMS.1.7v1"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }
   
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}


test_BroadcastRecordingMode_Multiple if {
    PolicyId := "MS.TEAMS.1.7v1"

    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            },
            {
                "Identity": "Tag:TestPolicy", # Should be ignored
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}