package onedrive
import future.keywords


#
# Policy 1
#--
test_ExternalUserExpirationRequired_Correct if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": {
            "ExternalUserExpirationRequired" : true
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpirationRequired_Incorrect if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": {
            "ExternalUserExpirationRequired" : false
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}


#
# Policy 2
#--
test_ExternalUserExpireInDays_Correct if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": {
            "ExternalUserExpireInDays" : 30
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Incorrect_V1 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": {
            "ExternalUserExpireInDays" : 31
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_ExternalUserExpireInDays_Incorrect_V2 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": {
            "ExternalUserExpireInDays" : 29
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}