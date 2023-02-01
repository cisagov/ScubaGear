package sharepoint
import future.keywords


#
# Policy 1
#--
test_SharingCapability_Correct if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "SharingDomainRestrictionMode" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Incorrect_V1 if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2,
                "SharingDomainRestrictionMode" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Sharepoint sharing slider must be set to 'New and Existing Guests'"
}

test_SharingCapability_Incorrect_V2 if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "SharingDomainRestrictionMode" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'Limit external sharing by domain' must be enabled"
}

test_SharingCapability_Incorrect_V3 if {
    ControlNumber := "Sharepoint 2.2"
    Requirement := "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2,
                "SharingDomainRestrictionMode" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}