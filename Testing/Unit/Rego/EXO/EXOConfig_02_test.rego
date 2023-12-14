package exo_test
import future.keywords
import data.exo
import data.utils.report.NotCheckedDetails
import data.utils.policy.TestResult
import data.utils.policy.TestResultContains
import data.utils.policy.PASS


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.EXO.2.1v1"

    Output := exo.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
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


    TestResult("MS.EXO.2.2v1", Output, PASS, true) == true
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

    TestResult("MS.EXO.2.2v1", Output, PASS, true) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: Test name"
    TestResult("MS.EXO.2.2v1", Output, ReportDetailString, false) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: Test name"
    TestResult("MS.EXO.2.2v1", Output, ReportDetailString, false) == true
}

# if we can make any assumptions about the order these domains
# will be printed in, hence the "contains" operator instead of ==
test_Rdata_Incorrect_V3 if {
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

    ReportDetailArrayStrs := [
        "2 agency domain(s) found in violation: ",
        "bad.com", # I'm not sure
        "2bad.com"
    ]
    TestResultContains("MS.EXO.2.2v1", Output, ReportDetailArrayStrs, false) == true
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

    TestResult("MS.EXO.2.2v1", Output, PASS, true) == true
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

    TestResult("MS.EXO.2.2v1", Output, PASS, true) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: bad.com"
    TestResult("MS.EXO.2.2v1", Output, ReportDetailString, false) == true
}
#--