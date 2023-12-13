package sharepoint_test
import future.keywords
import data.sharepoint
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# MS.SHAREPOINT.2.1v1
#--
test_DefaultSharingLinkType_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType": 1
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.2.1v1", Output, PASS) == true
}

test_DefaultSharingLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType": 2
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.2.1v1", Output, FAIL) == true
}
#--

#
# MS.SHAREPOINT.2.2v1
#--
test_DefaultLinkPermission_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission": 1
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.2.2v1", Output, PASS) == true
}

test_DefaultLinkPermission_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission": 2
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.2.2v1", Output, FAIL) == true
}
#--