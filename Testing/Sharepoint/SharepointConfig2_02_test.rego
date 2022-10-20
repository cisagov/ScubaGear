package sharepoint
import future.keywords


#
# Policy 1
#--
test_SharingCapability_Correct if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": {
            "SharingCapability" : 1
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Incorrect if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": {
            "SharingCapability" : 2
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}