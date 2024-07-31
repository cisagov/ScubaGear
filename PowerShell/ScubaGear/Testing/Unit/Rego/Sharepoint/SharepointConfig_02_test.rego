package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.2.1v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If default sharing link type is for specific people, the policy should pass.
# DefaultSharingLinkType == 1 for Specific People
# DefaultSharingLinkType == 2 for Only people in your organization
#
# Level 1: Easy
#
# Code Note: Take a look at MS.SHAREPOINT.1.1v1 unit test example first
#
test_DefaultSharingLinkType_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.2.1v1", Output, TODO, true) == true
}

test_DefaultSharingLinkType_Incorrect if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.2.1v1", Output, TODO, false) == true
}
#--

#
# Policy MS.SHAREPOINT.2.2v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If Default link permission is set to view, the policy should pass.
# DefaultLinkPermission == 1 view
# DefaultLinkPermission == 2 edit
#
# Level 1: Easy
#
# Code Note: Take a look at MS.SHAREPOINT.1.1v1 unit test example first
#
test_DefaultLinkPermission_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.2.2v1", Output, TODO, true) == true
}

test_DefaultLinkPermission_Incorrect if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.2.2v1", Output, TODO, false) == true
}
#--