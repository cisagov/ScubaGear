package teams
import future.keywords


#
# Policy 1
#--
test_AllowCloudRecording_Correct if {
    ControlNumber := "Teams 2.9"
    Requirement := "Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowCloudRecording_Incorrect if {
    ControlNumber := "Teams 2.9"
    Requirement := "Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllowCloudRecording_Multiple if {
    ControlNumber := "Teams 2.9"
    Requirement := "Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            },
            {
                "Identity": "Tag:TestPolicy",
                "AllowCloudRecording": true # This baseline only applies to the Global policy,
                # so no failure will be produced for the non-global policies
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

#
# Policy 2
#--
test_AllowCloudRecording_Correct_V1 if {
    ControlNumber := "Teams 2.9"
    Requirement := "For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency's tenant"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false,
                "AllowRecordingStorageOutsideRegion": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowCloudRecording_Correct_V2 if {
    ControlNumber := "Teams 2.9"
    Requirement := "For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency's tenant"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false,
                "AllowRecordingStorageOutsideRegion": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowCloudRecording_Incorrect if {
    ControlNumber := "Teams 2.9"
    Requirement := "For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency's tenant"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": true,
                "AllowRecordingStorageOutsideRegion": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allow cloud recording and storage outside of the tenant's region: Global"
}

test_AllowCloudRecording_Multiple if {
    ControlNumber := "Teams 2.9"
    Requirement := "For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency's tenant"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": true,
                "AllowRecordingStorageOutsideRegion": true
            },
            {
                "Identity": "Tag:custom",
                "AllowCloudRecording": true,
                "AllowRecordingStorageOutsideRegion": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allow cloud recording and storage outside of the tenant's region: ")
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:custom")
}