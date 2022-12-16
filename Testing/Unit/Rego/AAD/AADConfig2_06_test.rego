package aad
import future.keywords


#
# Policy 1
#--
test_AllowedToCreateApps_Correct if {
    ControlNumber := "AAD 2.6"
    Requirement := "Only administrators SHALL be allowed to register third-party applications"

    Output := tests with input as {
        "authorization_policies": {
            "DefaultUserRolePermissions": {
                "AllowedToCreateApps": false
            }
        }
    }

    # filter for just the output produced by the specific rule by 
    # checking 1) the control number and 2) the requirement string
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    # Each rule should produce exactly 1 line of output in the report
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedToCreateApps_Incorrect if {
    ControlNumber := "AAD 2.6"
    Requirement := "Only administrators SHALL be allowed to register third-party applications"

    Output := tests with input as {
        "authorization_policies": {
            "DefaultUserRolePermissions": {
                "AllowedToCreateApps": true
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}