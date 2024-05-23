package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.6.1v1
#--
# Todo write unit tests using bottom up approach

#
# Policy MS.EXO.6.2v1
#--
test_Domains_Calendar_Correct if {
    Output := exo.tests with input as {
        "sharing_policy": [
            {
                "Domains": [
                    "domain1",
                    "domain2"
                ],
                "Name": "A"
            }
        ]
    }

    TestResult("MS.EXO.6.2v1", Output, PASS, true) == true
}

test_Domains_Calendar_Incorrect if {
    Output := exo.tests with input as {
        "sharing_policy": [
            {
                "Domains": [
                    "*:CalendarSharingFreeBusyDetail",
                    "domain1:ContactsSharing"
                ],
                "Name": "A"
            }
        ]
    }

    ReportDetailString := "1 sharing polic(ies) are sharing calendar details with all domains by default: A"
    TestResult("MS.EXO.6.2v1", Output, ReportDetailString, false) == true
}
#--