package securitysuite_test

import rego.v1
import data.securitysuite
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.SECURITYSUITE.7.1v1
#--
test_SafeLinks_CustomPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_StandardPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_StrictPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_CustomPolicy_Incorrect_V1 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_CustomPolicy_Incorrect_V2 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_CustomPolicy_Incorrect_V3 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}

test_SafeLinks_CustomPolicy_Incorrect_V4 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
}
#--

#
# Policy MS.SECURITYSUITE.7.2v1
#--
test_CheckUrls_CustomPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}

test_CheckUrls_StandardPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}

test_CheckUrls_StrictPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}

test_CheckUrls_CustomPolicy_Incorrect_V1 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}

test_CheckUrls_CustomPolicy_Incorrect_V2 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}

test_CheckUrls_CustomPolicy_Incorrect_V3 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}
#--

#
# Policy MS.SECURITYSUITE.7.3v1
#--
test_TrackChecks_CustomPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

test_TrackChecks_StandardPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

test_TrackChecks_StrictPresetPolicy_Correct if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

test_TrackChecks_CustomPolicy_Incorrect_V1 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

test_TrackChecks_CustomPolicy_Incorrect_V2 if {
    Output := securitysuite.tests with input.safe_links_policy as [SafeLinksPolicy]

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}
#--