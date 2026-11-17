package si_test
import rego.v1
import data.si
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.SI.12.1v1
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.SI.12.1v1"

    Output := si.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--

#
# Policy MS.SI.12.2v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.SI.12.2v1"

    Output := si.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--

#
# Policy MS.SI.12.3v1
#--
test_NotImplemented_Correct_V3 if {
    PolicyId := "MS.SI.12.3v1"

    Output := si.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--

#
# Policy MS.SI.12.4v1
#--
test_NotImplemented_Correct_V4 if {
    PolicyId := "MS.SI.12.4v1"

    Output := si.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--
