package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.PASS


#
# MS.SECURITYSUITE.4.1v1
#--
test_Disabled_Correct_V1 if {
    Output := securitysuite.tests with input.protection_alerts as ProtectionAlerts
    TestResult("MS.SECURITYSUITE.4.1v1", Output, PASS, true) == true
}

test_Disabled_Correct_V2 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "7", "value": {
                "Disabled": false,
                "Name": "Successful exact data match upload"
                }}])
    Output := securitysuite.tests with input.protection_alerts as Alerts
    TestResult("MS.SECURITYSUITE.4.1v1", Output, PASS, true) == true
}

test_Disabled_Incorrect_V1 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "0/Disabled", "value": true}])
    Output := securitysuite.tests with input.protection_alerts as Alerts

    ReportDetailString := "1 disabled required alert(s) found: Suspicious email sending patterns detected"
    TestResult("MS.SECURITYSUITE.4.1v1", Output, ReportDetailString, false) == true
}

test_Disabled_Incorrect_V2 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "remove", "path": "0"}])
    Output := securitysuite.tests with input.protection_alerts as Alerts

    ReportDetailString := "1 disabled required alert(s) found: Suspicious email sending patterns detected"
    TestResult("MS.SECURITYSUITE.4.1v1", Output, ReportDetailString, false) == true
}
#--

#
# MS.SECURITYSUITE.4.2v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.SECURITYSUITE.4.2v1"

    Output := securitysuite.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--