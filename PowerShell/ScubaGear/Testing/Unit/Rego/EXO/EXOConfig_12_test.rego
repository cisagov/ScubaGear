package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.12.1v1
#--
test_IPAllowList_Correct_V1 if {
    Output := exo.tests with input.conn_filter as [ConnFilter]

    TestResult("MS.EXO.12.1v1", Output, PASS, true) == true
}

# it shouldn't matter that safe list is enabled
test_IPAllowList_Correct_V2 if {
    ConnFilter1 := json.patch(ConnFilter, [{"op": "add", "path": "EnableSafeList", "value": true}])

    Output := exo.tests with input.conn_filter as [ConnFilter1]

    TestResult("MS.EXO.12.1v1", Output, PASS, true) == true
}

test_IPAllowList_Incorrect if {
    ConnFilter1 := json.patch(ConnFilter, [{"op": "add", "path": "IPAllowList", "value": ["trust.me.please"]}])

    Output := exo.tests with input.conn_filter as [ConnFilter1]

    ReportDetailString := "1 connection filter polic(ies) with an IP allowlist: A"
    TestResult("MS.EXO.12.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.EXO.12.2v1
#--
test_EnableSafeList_Correct_V1 if {
    Output := exo.tests with input.conn_filter as [ConnFilter]

    TestResult("MS.EXO.12.2v1", Output, PASS, true) == true
}

test_EnableSafeList_Incorrect_V1 if {
    ConnFilter1 := json.patch(ConnFilter, [{"op": "add", "path": "EnableSafeList", "value": true}])

    Output := exo.tests with input.conn_filter as [ConnFilter1]

    ReportDetailString := "1 connection filter polic(ies) with a safe list: A"
    TestResult("MS.EXO.12.2v1", Output, ReportDetailString, false) == true
}

test_EnableSafeList_Correct_V2 if {
    ConnFilter1 := json.patch(ConnFilter, [{"op": "add", "path": "IPAllowList", "value": ["this.shouldnt.matter"]}])

    Output := exo.tests with input.conn_filter as [ConnFilter1]

    TestResult("MS.EXO.12.2v1", Output, PASS, true) == true
}
#--