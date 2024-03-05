package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.7.1v1
#--
test_FromScope_Correct if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "Enforce",
                "PrependSubject": "External"
            }
        ]
    }

    TestResult("MS.EXO.7.1v1", Output, PASS, true) == true
}

test_FromScope_Incorrect_V1 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "",
                "State": "Enabled",
                "Mode": "Audit",
                "PrependSubject": "External"
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V2 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "NotInOrganization",
                "State": "Disabled",
                "Mode": "Audit",
                "PrependSubject": "External"
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V3 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "",
                "State": "Enabled",
                "Mode": "AuditAndNotify",
                "PrependSubject": "External"
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Incorrect_V4 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "NotInOrganization",
                "State": "Disabled",
                "Mode": "AuditAndNotify",
                "PrependSubject": "External"
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_FromScope_Multiple_Correct if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "",
                "State": "Disabled",
                "Mode": "Enforce",
                "PrependSubject": "External"
            },
            {
                "FromScope": "",
                "State": "Enabled",
                "Mode": "Audit",
                "PrependSubject": "External"
            },
            {
                "FromScope": "",
                "State": "Enabled",
                "Mode": "AuditAndNotify",
                "PrependSubject": "External"
            },
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "Enforce",
                "PrependSubject": "External"
            }
        ]
    }

    TestResult("MS.EXO.7.1v1", Output, PASS, true) == true
}

test_FromScope_Multiple_Incorrect if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "",
                "State": "Enabled",
                "Mode": "Enforce",
                "PrependSubject": "External"
            },
            {
                "FromScope": "Hello there",
                "State": "Enabled",
                "Mode": "Audit",
                "PrependSubject": "External"
            },
            {
                "FromScope": "Hello there",
                "State": "Enabled",
                "Mode": "AuditAndNotify",
                "PrependSubject": "External"
            },
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "Audit",
                "PrependSubject": "External"
            },
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "AuditAndNotify",
                "PrependSubject": "External"
            },
            {
                "FromScope": "NotInOrganization",
                "State": "Disabled",
                "Mode": "Enforce",
                "PrependSubject": "External"
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_PrependSubject_IncorrectV1 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "Enforce",
                "PrependSubject": null
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}

test_PrependSubject_IncorrectV2 if {
    Output := exo.tests with input as {
        "transport_rule": [
            {
                "FromScope": "NotInOrganization",
                "State": "Enabled",
                "Mode": "Enforce",
                "PrependSubject": ""
            }
        ]
    }

    ReportDetailStr := "No transport rule found that applies warnings to emails received from outside the organization"
    TestResult("MS.EXO.7.1v1", Output, ReportDetailStr, false) == true
}
#--