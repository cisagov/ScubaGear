package exo
import future.keywords


#
# Policy 1
#--
test_Domains_Contacts_Correct if {
    ControlNumber := "EXO 2.6"
    Requirement := "Contact folders SHALL NOT be shared with all domains, although they MAY be shared with specific domains"
    
    Output := tests with input as {
        "sharing_policy": {
            "Domains" : [
                "domain1", 
                "domain2"
            ]
        }  
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Domains_Contacts_Incorrect if {
    ControlNumber := "EXO 2.6"
    Requirement := "Contact folders SHALL NOT be shared with all domains, although they MAY be shared with specific domains"

    Output := tests with input as {
        "sharing_policy": {
            "Domains" : [
                "domain1", 
                "*"
            ]
        }  
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing will all domains by default"
}

#
# Policy 2
#--
test_Domains_Calender_Correct if {
    ControlNumber := "EXO 2.6"
    Requirement := "Calendar details SHALL NOT be shared with all domains, although they MAY be shared with specific domains"

    Output := tests with input as {
        "sharing_policy": {
            "Domains" : [
                "domain1", 
                "domain2"
            ]
        }  
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Domains_Calender_Incorrect if {
    ControlNumber := "EXO 2.6"
    Requirement := "Calendar details SHALL NOT be shared with all domains, although they MAY be shared with specific domains"

    Output := tests with input as {
        "sharing_policy": {
            "Domains" : [
                "domain1", 
                "*"
            ]
        }  
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Wildcard domain (\"*\") in shared domains list, enabling sharing will all domains by default"
}