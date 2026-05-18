package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.PASS


#
# MS.SECURITYSUITE.4.1v1
#--
test_Correct_All_Required_Alerts_Enabled if {
    Output := securitysuite.tests with input.protection_alerts as ProtectionAlerts
    TestResult("MS.SECURITYSUITE.4.1v1", Output, PASS, true) == true
}

test_Correct_Additional_Alerts_In_List if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "7", "value": {
                "Disabled": false,
                "Name": "Successful exact data match upload"
                }}])
    Output := securitysuite.tests with input.protection_alerts as Alerts
    TestResult("MS.SECURITYSUITE.4.1v1", Output, PASS, true) == true
}

test_Incorrect_Empty_Array if {
    Alerts := []
    Output := securitysuite.tests with input.protection_alerts as Alerts

    ReportDetailString := concat("", ["7 disabled required alert(s) found: ",
        "A potentially malicious URL click was detected, Messages have been delayed, ",
        "Suspicious Email Forwarding Activity, Suspicious connector activity, ",
        "Suspicious email sending patterns detected, Tenant restricted from sending email, ",
        "Tenant restricted from sending unprovisioned email"])
    TestResult("MS.SECURITYSUITE.4.1v1", Output, ReportDetailString, false) == true
}

test_Incorrect_One_Disabled_Alert if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "0/Disabled", "value": true}])
    Output := securitysuite.tests with input.protection_alerts as Alerts

    ReportDetailString := "1 disabled required alert(s) found: Suspicious email sending patterns detected"
    TestResult("MS.SECURITYSUITE.4.1v1", Output, ReportDetailString, false) == true
}

test_Incorrect_Two_Disabled_Alerts if {
    Alerts := json.patch(ProtectionAlerts, [{"op": "add", "path": "0/Disabled", "value": true}, 
        {"op": "add", "path": "1/Disabled", "value": true}])
    Output := securitysuite.tests with input.protection_alerts as Alerts

    ReportDetailString := concat("", ["2 disabled required alert(s) found: ",
        "Suspicious Email Forwarding Activity, Suspicious email sending patterns detected"])
    TestResult("MS.SECURITYSUITE.4.1v1", Output, ReportDetailString, false) == true
}

test_Incorrect_One_Alert_Missing if {
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