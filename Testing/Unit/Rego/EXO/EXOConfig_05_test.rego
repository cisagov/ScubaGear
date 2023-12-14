package exo_test
import future.keywords
import data.exo
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# Policy 1
#--
test_SmtpClientAuthenticationDisabled_Correct if {
    Output := exo.tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled": true,
                "Name": "A"
            }
        ]
    }

    CorrectTestResult("MS.EXO.5.1v1", Output, PASS) == true
}

test_SmtpClientAuthenticationDisabled_Incorrect if {
    Output := exo.tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled": false,
                "Name": "A"
            }
        ]
    }

    IncorrectTestResult("MS.EXO.5.1v1", Output, FAIL) == true
}
#--