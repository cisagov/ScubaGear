package exo
import future.keywords


#
# Policy 1
#--
test_Rdata_Correct if {
    PolicyId := "MS.EXO.4.1v1"

    Output := tests with input as {
        "dmarc_records":[
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Incorrect if {
    PolicyId := "MS.EXO.4.1v1"

    Output := tests with input as {
        "dmarc_records":[
            {
                "rdata" : [], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

test_Rdata_Incorrect_V2 if {
    PolicyId := "MS.EXO.4.1v1"

    Output := tests with input as {
        "dmarc_records":[  
            {
                "rdata" : ["v=DMARC1"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

test_Rdata_Incorrect_V3 if {
    PolicyId := "MS.EXO.4.1v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            },
            {
                "rdata" : [], 
                "domain" : "bad.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            },
            {
                "rdata" : ["spf1 "], 
                "domain" : "bad.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 2 agency domain(s) found in violation: bad.name"
}

#
# Policy 2
#--
test_Rdata_Correct_V2 if {
    PolicyId := "MS.EXO.4.2v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Incorrect_V4 if {
    PolicyId := "MS.EXO.4.2v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=none; mailto:reports@dmarc.cyber.dhs.gov mailto:jsmith@dhs.gov mailto:jsomething@dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

test_Rdata_Incorrect_V5 if {
    PolicyId := "MS.EXO.4.2v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; mailto:reports@dmarc.cyber.dhs.gov mailto:jsmith@dhs.gov mailto:jsomething@dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

#
# Policy 3
#--
test_Rdata_Correct_V3 if {
    PolicyId := "MS.EXO.4.3v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Incorrect_V6 if {
    PolicyId := "MS.EXO.4.3v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100;"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

test_Rdata_Incorrect_V7 if {
    PolicyId := "MS.EXO.4.3v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@wrong.address"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}

#
# Policy 4
#--
test_Rdata_Incorrect_V4 if {
    PolicyId := "MS.EXO.4.4v1"

    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Rdata_Incorrect_V8 if {
    PolicyId := "MS.EXO.4.4v1"
    
    Output := tests with input as {
        "dmarc_records": [
            {
                "rdata" : ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov"], 
                "domain" : "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata" : ["spf1 "], 
                "domain" : "test.name"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 of 1 agency domain(s) found in violation: test.name"
}