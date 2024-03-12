package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.12.1v1
#--
test_IPAllowList_Correct_V1 if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [],
                "EnableSafeList": false,
                "Name": "A"
            }
        ]
    }

    TestResult("MS.EXO.12.1v1", Output, PASS, true) == true
}

# it shouldn't matter that safe list is enabled
test_IPAllowList_Correct_V2 if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [],
                "EnableSafeList": true,
                "Name": "A"
            }
        ]
    }

    TestResult("MS.EXO.12.1v1", Output, PASS, true) == true
}

test_IPAllowList_Incorrect if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [
                    "trust.me.please"
                ],
                "EnableSafeList": false,
                "Name": "A"
            }
        ]
    }

    ReportDetailString := "1 connection filter polic(ies) with an IP allowlist: A"
    TestResult("MS.EXO.12.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.EXO.12.2v1
#--
test_EnableSafeList_Correct_V1 if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [],
                "EnableSafeList": false,
                "Name": "A"
            }
        ]
    }

    TestResult("MS.EXO.12.2v1", Output, PASS, true) == true
}

test_EnableSafeList_Incorrect_V1 if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [],
                "EnableSafeList": true,
                "Name": "A"
            }
        ]
    }

    ReportDetailString := "1 connection filter polic(ies) with a safe list: A"
    TestResult("MS.EXO.12.2v1", Output, ReportDetailString, false) == true
}

test_EnableSafeList_Correct_V2 if {
    Output := exo.tests with input as {
        "conn_filter": [
            {
                "IPAllowList": [
                    "this.shouldnt.matter"
                ],
                "EnableSafeList": false,
                "Name": "A"
            }
        ]
    }

    TestResult("MS.EXO.12.2v1", Output, PASS, true) == true
}
#--