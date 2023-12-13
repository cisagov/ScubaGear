package exo_test
import future.keywords
import data.exo
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean


CorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

IncorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

PASS := ReportDetailsBoolean(true)


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.EXO.2.1v1"

    Output := exo.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    IncorrectTestResult(PolicyId, Output, ReportDetailString) == true
}
#--

#
# Policy 2
#--
test_Rdata_Correct_V1 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 "
                ],
                "domain": "Test name"
            }
        ]
    }


    CorrectTestResult("MS.EXO.2.2v1", Output, PASS) == true
}

test_Rdata_Correct_V2 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 something"
                ],
                "domain": "Test name"
            }
        ]
    }

    CorrectTestResult("MS.EXO.2.2v1", Output, PASS) == true
}

test_Rdata_Incorrect_V1 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "Test name"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: Test name"
    IncorrectTestResult("MS.EXO.2.2v1", Output, ReportDetailString) == true
}

test_Rdata_Incorrect_V2 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    ""
                ],
                "domain": "Test name"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: Test name"
    IncorrectTestResult("MS.EXO.2.2v1", Output, ReportDetailString) == true
}

test_Rdata_Incorrect_V3 if {
    PolicyId := "MS.EXO.2.2v1"

    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 "
                ],
                "domain": "good.com"
            },
            {
                "rdata": [
                    ""
                ],
                "domain": "bad.com"
            },
            {
                "rdata": [
                    ""
                ],
                "domain": "2bad.com"
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    contains(RuleOutput[0].ReportDetails, "2 of 3 agency domain(s) found in violation: ")
    startswith(RuleOutput[0].ReportDetails, "2 of 3 agency domain(s) found in violation: ")
    contains(RuleOutput[0].ReportDetails, "bad.com") # I'm not sure

    # if we can make any assumptions about the order these domains
    # will be printed in, hence the "contains" operator instead of ==
    contains(RuleOutput[0].ReportDetails, "2bad.com")
}

test_Rdata_Multiple_Correct_V1 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 ",
                    "extra stuff that shouldn't matter"
                ],
                "domain": "good.com"
            }
        ]
    }

    CorrectTestResult("MS.EXO.2.2v1", Output, PASS) == true
}

test_Rdata_Multiple_Correct_V2 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "extra stuff that shouldn't matter",
                    "v=spf1 "
                ],
                "domain": "good.com"
            }
        ]
    }

    CorrectTestResult("MS.EXO.2.2v1", Output, PASS) == true
}

test_Rdata_Multiple_Incorrect if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "extra stuff that shouldn't matter",
                    "hello world"
                ],
                "domain": "bad.com"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: bad.com"
    IncorrectTestResult("MS.EXO.2.2v1", Output, ReportDetailString) == true
}
#--