# package name must have _test on the end if it is a unit test file
package sharepoint_test
# This import is default for all rego files to use keywords with & as
import rego.v1
# Imported sharepoint package for unit tests
import data.sharepoint
# These imports are the functions in the Utils/ReportDetails.rego
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
# These imports are the functions in the Utils/KeyFunctions.rego
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


# IMPORTANT comment structure, read the CONTENTSTYLEGUIDE.md!
#
# Policy MS.SHAREPOINT.1.1v1
#--

# Sharepoint Rego Unit Test Example
#
# Code logic: test_ MUST start each unit test name (rule set). _Correct ends the unit test name if the case results in a requirements met. _Incorrect
# ends the unit test if the case results in a requirements not met. The key values that are altered during the unit test should be the middle of the
# unit test name. Lastly there should not be any duplicate test names, so _V# should be appended to the end to prevent duplicates. This type of unit
# tests are called (by SCuBA) Basic Top Down approach. These tests are characterized by the policies being fed a hard coded json. This method is prone to
# copy & paste errors. Continuing logic explination in rule set.
test_SharingCapability_Correct_V1 if {
    # A hard coded json is bound as the input for all tests rule set in the sharepoint package (SharepointConfig.rego) and run results are stored in
    # the Output variable. To be clear ALL tests rule sets are run, so we have to filter later for the specific policy we want.
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 0
            }
        ]
    }

    # This is a key function to simplify unit testing. Just pass the specific policy id you are testing, the Output var, what string the report
    # details should contain, and if requrement met is true or false. The result of TestResult() should ALWAYS equal true.
    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

# Because of the OR case there is another possible _Correct case
test_SharingCapability_Correct_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 3
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

test_SharingCapability_Incorrect_V1 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 1
            }
        ]
    }

    # Notice with _Incorrect case the boolean passed is false instead of true
    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}

test_SharingCapability_Incorrect_V2 if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "SharingCapability": 2
            }
        ]
    }

    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.2v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If OneDriveSharingCapability is set to Only People In Organization OR Existing Guests, the policy should pass.
#
# Level 1: Easy
#
# Code Note: I have left the tests mostly fleshed out, only need to add the json. Look at the example above if you need help.
#
test_OneDriveSharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.2v1", Output, TODO, true) == true
}

test_OneDriveSharingCapability_Correct_V2 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.2v1", Output, TODO, true) == true
}

test_OneDrive_PnP_Flag_Incorrect if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Output := sharepoint.tests with input as {}

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}

test_OneDriveSharingCapability_Incorrect_V1 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.2v1", Output, TODO, false) == true
}

test_OneDriveSharingCapability_Incorrect_V2 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.2v1", Output, TODO, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.3v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If Sharing Domain Restriction Mode is enabled AND SharingCapability != Only People In Your Organization, the policy should pass.
# SharingDomainRestrictionMode == 0 Unchecked
# SharingDomainRestrictionMode == 1 Checked
#
# Level 1: Easy
#
# Code Note: Try previous challenge first
#
test_SharingDomainRestrictionMode_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    Output := sharepoint.tests with input as {}

    PolicyId := "MS.SHAREPOINT.1.3v1"
    ReportDetailsString := TODO
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_Anyone_Correct if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_NewExistingGuests_Correct if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_ExistingGuests_Correct if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_NewExistingGuests_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_ExistingGuests_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_Anyone_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := TODO
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.4v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If SharingCapability is not set to Only People In Organization and require account login to be the one on the invite enabled,
# the policy should pass.
#
# Level 1: Easy
#
# Code Note: Try previous challenge first
#
test_SameAccount_NotApplicable_V1 if {
    Output := sharepoint.tests with input as {}

    PolicyId := "MS.SHAREPOINT.1.4v1"
    ReportDetailsString := ""
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_SameAccount_NotApplicable_V2 if {
    Output := sharepoint.tests with input as {}

    PolicyId := "MS.SHAREPOINT.1.4v1"
    ReportDetailsString := ""
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_SameAccount_Correct_V1 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.4v1", Output, TODO, true) == true
}

test_SameAccount_Incorrect if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.1.4v1", Output, TODO, false) == true
}
#--