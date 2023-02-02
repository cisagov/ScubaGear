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
                "OneDriveRequestFilesLinkExpirationInDays" : 31    

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
                "OneDriveLoopSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : 1,
                "OneDriveRequestFilesLinkExpirationInDays" : 30   
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
                "OneDriveRequestFilesLinkExpirationInDays" : 30   
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration date is not set"
}

test_ExternalUserExpirationRequired_Incorrect_V2 if {
    ControlNumber := "OneDrive 2.2"
    Requirement := "An expiration date SHOULD be set for Anyone links"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveLoopSharingCapability" : 2,
                "RequireAnonymousLinksExpireInDays" : 1,
                "OneDriveRequestFilesLinkExpirationInDays" : 10   
            }
        ]        
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Expiration date is not 30"
}
