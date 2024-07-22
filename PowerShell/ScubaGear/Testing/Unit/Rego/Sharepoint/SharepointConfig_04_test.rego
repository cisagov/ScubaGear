package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.4.1v1
#--

# Sharepoint Rego Unit Test Example
#
# Policy logic: Not Implemented
#
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.4.1v1"

    # Have to bind something to input to run
    Output := sharepoint.tests with input as { }

    # Use the same function used for the report details, because html links are embeded, it is impossible to resonable hard code the string
    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--

#
# Policy MS.SHAREPOINT.4.2v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If users are preventedfrom running custom script on self-service created sites, the policy should pass.
# 1 == Allow users to run custom script on self-service created sites
# 2 == Prevent users from running custom script on self-service created sites
#
# Level 1: Easy
#
# Code Note: Take a look at MS.SHAREPOINT.1.1v1 unit test example first
#
test_DenyAddAndCustomizePages_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.4.2v1", TODO, TODO, TODO) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.4.2v1", TODO, TODO, TODO) == true
}
#--