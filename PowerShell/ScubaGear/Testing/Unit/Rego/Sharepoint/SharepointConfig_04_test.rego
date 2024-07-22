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
    Output := sharepoint.tests with input.SPO_site as [SPOSite]

    TestResult("MS.SHAREPOINT.4.2v1", Output, PASS, true) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Site := json.patch(SPOSite, [{"op": "add", "path": "DenyAddAndCustomizePages", "value": 1}])

    Output := sharepoint.tests with input.SPO_site as [Site]

    TestResult("MS.SHAREPOINT.4.2v1", Output, FAIL, false) == true
}
#--