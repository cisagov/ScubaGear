package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.6.1v1
#--
test_Domains_Contacts_Correct if {
    Output := exo.tests with input.sharing_policy as [SharingPolicy]

    TestResult("MS.EXO.6.1v1", Output, PASS, true) == true
}

test_Domains_Contacts_Incorrect if {
    SharingPolicy1 := json.patch(SharingPolicy, [{"op": "add", "path": "Domains", 
                                                    "value":["*:ContactsSharing", "domain1:CalendarSharingFreeBusyDetail"]}])

    Output := exo.tests with input.sharing_policy as [SharingPolicy1]

    ReportDetailString := "1 sharing polic(ies) are sharing contacts folders with all domains by default: A"
    TestResult("MS.EXO.6.1v1", Output, ReportDetailString, false) == true

    # print(count(RuleOutput)==1)
    # notror := RuleOutput[0].RequirementMet
    # trace(notror)
    # ReportDetailString :=
    #    "Wildcard domain (\"*\") in shared domains list, enabling sharing will all domains by default"
    # print(RuleOutput[0].ReportDetails == ReportDetailString)
}

#
# Policy MS.EXO.6.2v1
#--
test_Domains_Calendar_Correct if {
    Output := exo.tests with input.sharing_policy as [SharingPolicy]

    TestResult("MS.EXO.6.2v1", Output, PASS, true) == true
}

test_Domains_Calendar_Incorrect if {
    SharingPolicy1 := json.patch(SharingPolicy, [{"op": "add", "path": "Domains", "value":
                                                    ["*:CalendarSharingFreeBusyDetail", "domain1:ContactsSharing"]}])

    Output := exo.tests with input.sharing_policy as [SharingPolicy1]

    ReportDetailString := "1 sharing polic(ies) are sharing calendar details with all domains by default: A"
    TestResult("MS.EXO.6.2v1", Output, ReportDetailString, false) == true
}
#--