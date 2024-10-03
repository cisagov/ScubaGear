package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.key.TestResult
import data.utils.report.NotCheckedDeprecation



#
# Policy MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    PolicyId := "MS.SHAREPOINT.4.2v1"

    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]
    
    TestResult(PolicyId, Output, NotCheckedDeprecation, false) == true
}
#--
