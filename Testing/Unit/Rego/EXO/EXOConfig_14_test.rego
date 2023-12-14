package exo_test
import future.keywords
import data.exo
import data.utils.report.DefenderMirrorDetails
import data.utils.policy.TestResult


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.EXO.14.1v1"

    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# Policy 2
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.EXO.14.2v1"

    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# Policy 3
#--
test_3rdParty_Correct_V3 if {
    PolicyId := "MS.EXO.14.3v1"

    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--