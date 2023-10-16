package exo
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.EXO.2.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 2
#--
test_Rdata_Correct if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["v=spf1 "],
                "domain" : "Test name"
            }
        ]
    }


    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Correct_V2 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["v=spf1 something"],
                "domain" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Incorrect if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["spf1 "],
                "domain" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: Test name"
}

test_Rdata_Incorrect_V2 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : [""],
                "domain" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: Test name"
}

test_Rdata_Incorrect_V3 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["v=spf1 "],
                "domain" : "good.com"
            },
            {
                "rdata" : [""],
                "domain" : "bad.com"
            },
            {
                "rdata" : [""],
                "domain" : "2bad.com"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    contains(RuleOutput[0].ReportDetails, "2 of 3 agency domain(s) found in violation: ")
    startswith(RuleOutput[0].ReportDetails, "2 of 3 agency domain(s) found in violation: ")
    contains(RuleOutput[0].ReportDetails, "bad.com") # I'm not sure

    # if we can make any assumptions about the order these domains
    # will be printed in, hence the "contains" operator instead of ==
    contains(RuleOutput[0].ReportDetails, "2bad.com")
}

test_Rdata_Multiple_Correct_V1 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["v=spf1 ", "extra stuff that shouldn't matter"], 
                "domain" : "good.com"
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Multiple_Correct_V2 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["extra stuff that shouldn't matter", "v=spf1 "],
                "domain" : "good.com"
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Multiple_Incorrect if {
    PolicyId := "MS.EXO.2.2v1"

    Output := tests with input as {
        "spf_records": [
            {
                "rdata" : ["extra stuff that shouldn't matter", "hello world"],
                "domain" : "bad.com"
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: bad.com"
}