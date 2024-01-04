package aad_test
import future.keywords
import data.aad
import data.utils.key.TestResult


#
# Policy MS.AAD.6.1v1
#--

# User passwords are set to not expire if they equal INT_MAX
INT_MAX := 2147483647

test_PasswordValidityPeriodInDays_Correct if {
    Output := aad.tests with input as { 
        "domain_settings" : [
            {
                "Id" : "test.url.com",
                "PasswordValidityPeriodInDays" : INT_MAX,
                "IsVerified" : true
            },
            {
                "Id" : "test1.url.com",
                "PasswordValidityPeriodInDays" : INT_MAX,
                "IsVerified" : true
            },
            {   
                "Id" : "test2.url.com",
                "PasswordValidityPeriodInDays" : INT_MAX,
                "IsVerified" : true
            }
        ]
    }

    ReportDetailString := "Requirement met"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, true) == true
}

test_PasswordValidityPeriodInDays_Incorrect if {
    Output := aad.tests with input as { 
        "domain_settings" : [
            {
                "Id" : "test.url.com",
                "PasswordValidityPeriodInDays" : 0,
                "IsVerified" : true
            },
            {
                "Id" : "test1.url.com",
                "PasswordValidityPeriodInDays" : 0,
                "IsVerified" : true
            },
            {   
                "Id" : "test2.url.com",
                "PasswordValidityPeriodInDays" : INT_MAX,
                "IsVerified" : true
            }
        ]
    }

    ReportDetailString := "2 domain(s) failed:<br/>test.url.com, test1.url.com"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}

test_IsVerified_Correct if {
    Output := aad.tests with input as { 
        "domain_settings" : [
            {
                "Id" : "test.url.com",
                "PasswordValidityPeriodInDays" : 0,
                "IsVerified" : null
            },
            {
                "Id" : "test1.url.com",
                "PasswordValidityPeriodInDays" : 0,
                "IsVerified" : false
            },
            {   
                "Id" : "test2.url.com",
                "PasswordValidityPeriodInDays" : INT_MAX,
                "IsVerified" : true
            }
        ]
    }

    ReportDetailString := "Requirement met"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, true) == true
}
#--