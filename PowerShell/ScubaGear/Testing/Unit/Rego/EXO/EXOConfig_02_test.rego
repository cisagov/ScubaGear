package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.EXO.2.2v2
#--
test_Rdata_Correct_V1 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 -all"
                ],
                "domain": "Test name"
            }
        ]
    }


    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Correct_V2 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 redirect"
                ],
                "domain": "Test name"
            }
        ]
    }

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
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
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
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
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
}

# if we can make any assumptions about the order these domains
# will be printed in, hence the "contains" operator instead of ==
test_Rdata_Incorrect_V3 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 -all"
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
    TestResultContains("MS.EXO.2.2v2", Output, ReportDetailArrayStrs, false) == true
}

test_Rdata_Multiple_Correct_V1 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "v=spf1 -all",
                    "extra stuff that shouldn't matter"
                ],
                "domain": "good.com"
            }
        ]
    }

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Multiple_Correct_V2 if {
    Output := exo.tests with input as {
        "spf_records": [
            {
                "rdata": [
                    "extra stuff that shouldn't matter",
                    "v=spf1 -all"
                ],
                "domain": "good.com"
            }
        ]
    }

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Multiple_Correct_V3 if {
    # Test SPF redirect
    Output := exo.tests with input as {
        "spf_records": [
            {
                "domain": "test1.name",
                "rdata": ["v=spf1 redirect=_spf.example.com"]
            }
        ],
        "domains": ["test1.name"]
    }

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
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
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
}
#--