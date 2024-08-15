package defender_test
import rego.v1
import data.defender
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.DEFENDER.5.1v1
#--
test_Disabled_Correct_V1 if {
    Output := defender.tests with input.protection_alerts as ProtectionAlerts

    TestResult("MS.DEFENDER.5.1v1", Output, PASS, true) == true
}

test_Disabled_Correct_V2 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "9", "value": {
                "Disabled": false,
                "Name": "Successful exact data match upload"
                }}])
    Output := defender.tests with input.protection_alerts as Alerts

    TestResult("MS.DEFENDER.5.1v1", Output, PASS, true) == true
}

test_Disabled_Incorrect_V1 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "0/Disabled", "value": true}])
    Output := defender.tests with input.protection_alerts as Alerts

    ReportDetailString := "1 disabled required alert(s) found: Suspicious email sending patterns detected"
    TestResult("MS.DEFENDER.5.1v1", Output, ReportDetailString, false) == true
}

test_Disabled_Incorrect_V2 if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "remove", "path": "0"}])
    Output := defender.tests with input.protection_alerts as Alerts

    ReportDetailString := "1 disabled required alert(s) found: Suspicious email sending patterns detected"
    TestResult("MS.DEFENDER.5.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.DEFENDER.5.2v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.5.2v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--