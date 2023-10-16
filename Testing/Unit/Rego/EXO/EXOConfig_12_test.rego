package exo
import future.keywords


#
# Policy 1
#--
test_IPAllowList_Correct_V1 if {
    PolicyId := "MS.EXO.12.1v1"

    Output := tests with input as {
        "conn_filter": [
            {
                "IPAllowList" : [],
                "EnableSafeList": false,
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_IPAllowList_Correct_V2 if {
    PolicyId := "MS.EXO.12.1v1"

    Output := tests with input as {
        "conn_filter":
        [
            {
                "IPAllowList" : [],
                "EnableSafeList": true,
                "Name":"A"
            } # it shouldn't matter that safe list is enabled
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_IPAllowList_Incorrect if {
    PolicyId := "MS.EXO.12.1v1"

    Output := tests with input as {
        "conn_filter": [
            {
                "IPAllowList" : ["trust.me.please"],
                "EnableSafeList": false,
                "Name" : "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 connection filter polic(ies) with an IP allowlist: A"
}

#
# Policy 2
#--
test_EnableSafeList_Correct_V1 if {
    PolicyId := "MS.EXO.12.2v1"

    Output := tests with input as {
        "conn_filter": [
            {
                "IPAllowList" : [],
                "EnableSafeList": false,
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeList_Incorrect_V1 if {
    PolicyId := "MS.EXO.12.2v1"

    Output := tests with input as {
        "conn_filter": [
            {
                "IPAllowList" : [],
                "EnableSafeList": true,
                "Name" : "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 connection filter polic(ies) with a safe list: A"
}

test_EnableSafeList_Correct_V2 if {
    PolicyId := "MS.EXO.12.2v1"

    Output := tests with input as {
        "conn_filter": [
            {
                "IPAllowList" : ["this.shouldnt.matter"],
                "EnableSafeList": false,
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}