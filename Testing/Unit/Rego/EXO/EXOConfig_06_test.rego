package exo
import future.keywords


#
# Policy 1
#--
test_Domains_Contacts_Correct if {
    PolicyId := "MS.EXO.6.1v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "domain1",
                    "domain2"
                ],
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Domains_Contacts_Incorrect if {
    PolicyId := "MS.EXO.6.1v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "*:ContactsSharing",
                    "domain1:CalendarSharingFreeBusyDetail"
                ],
                "Name": "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 sharing polic(ies) are sharing contacts folders with all domains by default: A"

    # print(count(RuleOutput)==1)
    # notror := RuleOutput[0].RequirementMet
    # trace(notror)
    # print(RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing will all domains by default")
}

#
# Policy 2
#--
test_Domains_Calendar_Correct if {
    PolicyId := "MS.EXO.6.2v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "domain1",
                    "domain2"
                ],
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Domains_Calendar_Incorrect if {
    PolicyId := "MS.EXO.6.2v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "*:CalendarSharingFreeBusyDetail",
                    "domain1:ContactsSharing"
                ],
                "Name": "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 sharing polic(ies) are sharing calendar details with all domains by default: A"
}