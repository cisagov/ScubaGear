package onedrive
import future.keywords


#
# Policy 1
#--
test_DefaultLinkPermission_Correct_V1 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 1,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Anyone links are disabled"
}

test_DefaultLinkPermission_Correct_V2 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultLinkPermission_Correct_V2 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultLinkPermission_Incorrect if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: both files and folders are not limited to view for Anyone"
}

test_DefaultLinkPermission_Incorrect_V2 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 2,
                "FolderAnonymousLinkType" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: files are not limited to view for Anyone"
}

test_DefaultLinkPermission_Incorrect_V3 if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
            {
                "OneDriveSharingCapability" : 2,
                "FileAnonymousLinkType" : 1,
                "FolderAnonymousLinkType" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: folders are not limited to view for Anyone"
}

test_UsingServicePrincipal if {
    ControlNumber := "OneDrive 2.3"
    Requirement := "Anyone link permissions SHOULD be limited to View"

    Output := tests with input as {
        "SPO_tenant_info": [
        ],
        "OneDrive_PnP_Flag": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically while using Service Principals. See Onedrive Secure Configuration Baseline policy 2.1 for instructions on manual check"
}