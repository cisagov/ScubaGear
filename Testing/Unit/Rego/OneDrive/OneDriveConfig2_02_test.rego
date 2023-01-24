package onedrive
import future.keywords

#
# Policy 1
#--
test_ExternalUserExpirationRequired_Correct_V1 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 1,
                "RequireAnonymousLinksExpireInDays" : 30,
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_ExternalUserExpirationRequired_Correct_V2 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 1,
                "RequireAnonymousLinksExpireInDays" : 15,
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_ExternalUserExpirationRequired_Correct_V3 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : 15,
            }
        ]        
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
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : -1,
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
test_ExternalUserExpireInDays_Correct_V1 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 1,
                "OneDriveRequestFilesLinkExpirationInDays" : 30
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_ExternalUserExpireInDays_Correct_V2 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 1,
                "OneDriveRequestFilesLinkExpirationInDays" : 15
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_ExternalUserExpireInDays_CorrectV_3 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "Expiration date SHOULD be set to thirty days"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 2,
                "OneDriveRequestFilesLinkExpirationInDays" : 30
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}
