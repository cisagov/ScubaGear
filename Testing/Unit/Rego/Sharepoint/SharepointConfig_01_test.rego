package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails


#
# MS.SHAREPOINT.1.1v1
#--
test_SharingCapability_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.1.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.1.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 3
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingCapability_Incorrect_V1 if {
    PolicyId := "MS.SHAREPOINT.1.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SharingCapability_Incorrect_V2 if {
    PolicyId := "MS.SHAREPOINT.1.1v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 2
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.SHAREPOINT.1.2v1
#--
test_OneDriveSharingCapability_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 0
            }
        ],
        "OneDrive_PnP_Flag": false   

    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneDriveSharingCapability_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 3
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 3
            }
        ],
        "OneDrive_PnP_Flag": true   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].Criticality == "Should/Not-Implemented"
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

test_OneDriveSharingCapability_Incorrect_V1 if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 1
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_OneDriveSharingCapability_Incorrect_V2 if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 2
            }
        ],
        "OneDrive_PnP_Flag": false   
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.SHAREPOINT.1.3v1
#--
test_SharingDomainRestrictionMode_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0,
                "SharingDomainRestrictionMode" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: external sharing is set to Only People In Organization"
}

test_SharingDomainRestrictionMode_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "SharingDomainRestrictionMode" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met: Note that we currently only check for approved external domains. Approved security groups are currently not being checked, see the baseline policy for instructions on a manual check"
}

test_SharingDomainRestrictionMode_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "SharingDomainRestrictionMode" : 0
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails =="Requirement not met: Note that we currently only check for approved external domains. Approved security groups are currently not being checked, see the baseline policy for instructions on a manual check"
}
#--

#
# MS.SHAREPOINT.1.4v1
#--
test_SameAccount_Correct_V1 if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0,
                "RequireAcceptingAccountMatchInvitedAccount" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SameAccount_Correct_V3 if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 0,
                "RequireAcceptingAccountMatchInvitedAccount" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SameAccount_Correct_V2 if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "RequireAcceptingAccountMatchInvitedAccount" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SameAccount_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability" : 1,
                "RequireAcceptingAccountMatchInvitedAccount" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--
