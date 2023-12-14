package sharepoint_test
import future.keywords
import data.sharepoint
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


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

    TestResult("MS.SHAREPOINT.2.1v1", Output, PASS, true) == true
}

test_DefaultSharingLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType": 2
            }
        ]
    }

    TestResult("MS.SHAREPOINT.2.1v1", Output, FAIL, false) == true
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

    TestResult("MS.SHAREPOINT.2.2v1", Output, PASS, true) == true
}

test_DefaultLinkPermission_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission": 2
            }
        ]
    }

    TestResult("MS.SHAREPOINT.2.2v1", Output, FAIL, false) == true
}
#--