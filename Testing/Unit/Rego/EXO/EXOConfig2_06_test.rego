package exo
import future.keywords


#
# Policy 1
#--
test_Domains_Contacts_Correct if {
    PolicyId := "MS.EXCHANGE.6.1v1"
 
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
    PolicyId := "MS.EXCHANGE.6.1v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "*", 
                    "domain1"
                ],
                "Name": "A"
            }  
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing with all domains by default"

    # print(count(RuleOutput)==1)
    # notror := RuleOutput[0].RequirementMet
    # trace(notror)
    # print(RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing will all domains by default")
}

#
# Policy 2
#--
test_Domains_Calender_Correct if {
    PolicyId := "MS.EXCHANGE.6.2v1"

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

test_Domains_Calender_Incorrect if {
    PolicyId := "MS.EXCHANGE.6.2v1"

    Output := tests with input as {
        "sharing_policy": [
            {
                "Domains" : [
                    "*", 
                    "domain1"
                ],
                "Name": "A"
            }  
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing with all domains by default"
}