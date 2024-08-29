package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.7.1v1
#--
test_FromScope_Correct if {
    Output := exo.tests with input.transport_rule as [TransportRule]

    TestResult("MS.EXO.7.1v1", Output, PASS, true) == true
}

test_FromScope_Incorrect_V1 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""},
                                                    {"op": "add", "path": "Mode", "value":"Audit"}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V2 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "State", "value":"Disabled"},
                                                    {"op": "add", "path": "Mode", "value":"Audit"}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V3 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""},
                                                    {"op": "add", "path": "Mode", "value":"AuditAndNotify"}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V4 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "State", "value":"Disabled"},
                                                    {"op": "add", "path": "Mode", "value":"AuditAndNotify"}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Multiple_Correct if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""},
                                                    {"op": "add", "path": "State", "value":"Disabled"}])
    TransportRule2 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""},
                                                    {"op": "add", "path": "Mode", "value":"Audit"}])
    TransportRule3 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""},
                                                    {"op": "add", "path": "Mode", "value":"AuditAndNotify"}])
    TransportRule4 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"}])

    Output := exo.tests with input.transport_rule as [TransportRule1, TransportRule2, TransportRule3, TransportRule4]

    TestResult("MS.EXO.7.1v1", Output, PASS, true) == true
}

test_FromScope_Multiple_Incorrect if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":""}])
    TransportRule2 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"Hello there"},
                                                    {"op": "add", "path": "Mode", "value":"Audit"}])
    TransportRule3 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"Hello there"},
                                                    {"op": "add", "path": "Mode", "value":"AuditAndNotify"}])
    TransportRule4 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "Mode", "value":"Audit"}])
    TransportRule5 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "Mode", "value":"AuditAndNotify"}])
    TransportRule6 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "State", "value":"Disabled"}])

    Output := exo.tests with input.transport_rule as [TransportRule1, TransportRule2, TransportRule3, TransportRule4, TransportRule5, TransportRule6]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_PrependSubject_IncorrectV1 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "PrependSubject", "value":null}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_PrependSubject_IncorrectV2 if {
    TransportRule1 := json.patch(TransportRule, [{"op": "add", "path": "FromScope", "value":"NotInOrganization"},
                                                    {"op": "add", "path": "PrependSubject", "value":""}])

    Output := exo.tests with input.transport_rule as [TransportRule1]

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}
#--