package sharepoint
import future.keywords


#
# Policy 1
#--
test_ExternalUserExpirationRequired_Correct if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpirationRequired" : true,
                "EmailAttestationRequired" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpirationRequired_Incorrect_V1 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpirationRequired" : false,
                "EmailAttestationRequired" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'Guest access to a site or OneDrive will expire automatically after this many days' must be enabled"
}

test_ExternalUserExpirationRequired_Incorrect_V2 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpirationRequired" : true,
                "EmailAttestationRequired" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'People who use a verification code must reauthenticate after this many days' must be enabled"
}

test_ExternalUserExpirationRequired_Incorrect_V3 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpirationRequired" : false,
                "EmailAttestationRequired" : false
            }
        ]
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
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 30,
                "EmailAttestationReAuthDays" : 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalUserExpireInDays_Incorrect_V1 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 29,
                "EmailAttestationReAuthDays" : 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'Guest access to a site or OneDrive will expire automatically after this many days' must be 30 days"
}

test_ExternalUserExpireInDays_Incorrect_V2 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 31,
                "EmailAttestationReAuthDays" : 30
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'Guest access to a site or OneDrive will expire automatically after this many days' must be 30 days"
}

test_EmailAttestationReAuthDays_Incorrect_V1 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 30,
                "EmailAttestationReAuthDays" : 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'People who use a verification code must reauthenticate after this many days' must be 30 days"
}

test_EmailAttestationReAuthDays_Incorrect_V2 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 30,
                "EmailAttestationReAuthDays" : 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: 'People who use a verification code must reauthenticate after this many days' must be 30 days"
}

test_Multi_Incorrect_V1 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 29,
                "EmailAttestationReAuthDays" : 29
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_Multi_Incorrect_V2 if {
    ControlNumber := "Sharepoint 2.4"
    Requirement := "Expiration timers SHOULD be set to 30 days"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "ExternalUserExpireInDays" : 31,
                "EmailAttestationReAuthDays" : 31
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}