package exo_test
import future.keywords
import data.exo
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.PASS


#
# Policy 1
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

    CorrectTestResult("MS.EXO.12.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.EXO.12.1v1", Output, PASS) == true
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
    IncorrectTestResult("MS.EXO.12.1v1", Output, ReportDetailString) == true
}
#--

#
# Policy 2
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

    CorrectTestResult("MS.EXO.12.2v1", Output, PASS) == true
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
    IncorrectTestResult("MS.EXO.12.2v1", Output, ReportDetailString) == true
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

    CorrectTestResult("MS.EXO.12.2v1", Output, PASS) == true
}
#--