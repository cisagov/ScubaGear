package exo_test
import rego.v1
import data.exo
import data.utils.report.DefenderMirrorDetails
import data.utils.key.TestResult


#
# Policy MS.EXO.9.1v1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.EXO.9.1v1"

    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.EXO.9.2v1
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.EXO.9.2v1"

    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.EXO.9.3v1
#--
test_3rdParty_Correct_V3 if {
    PolicyId := "MS.EXO.9.3v1"
    Output := exo.tests with input as { }

    ReportDetailString := DefenderMirrorDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--