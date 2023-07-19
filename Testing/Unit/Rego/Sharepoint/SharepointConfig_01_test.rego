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
        ]
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
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneDriveSharingCapability_Incorrect_V1 if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "OneDriveSharingCapability" : 1
            }
        ]
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
        ]
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
test_SharingDomainRestrictionMode_Correct if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingDomainRestrictionMode" : 1
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharingDomainRestrictionMode_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "SharingDomainRestrictionMode" : 0
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
# MS.SHAREPOINT.1.4v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.SHAREPOINT.1.5v1
#--
test_RequireAcceptingAccountMatchInvitedAccount_Correct if {
    PolicyId := "MS.SHAREPOINT.1.5v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
                "RequireAcceptingAccountMatchInvitedAccount" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_RequireAcceptingAccountMatchInvitedAccount_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.5v1"

    Output := tests with input as {
        "SPO_tenant": [
            {
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