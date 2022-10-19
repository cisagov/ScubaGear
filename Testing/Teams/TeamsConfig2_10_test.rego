package teams
import future.keywords


#
# Policy 1
#--
test_BroadcastRecordingMode_Correct if {
    ControlNumber := "Teams 2.10"
    Requirement := "Record an event SHOULD be set to Organizer can record"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BroadcastRecordingMode_Incorrect if {
    ControlNumber := "Teams 2.10"
    Requirement := "Record an event SHOULD be set to Organizer can record"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }
   
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}


test_BroadcastRecordingMode_Multiple if {
    ControlNumber := "Teams 2.10"
    Requirement := "Record an event SHOULD be set to Organizer can record"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}