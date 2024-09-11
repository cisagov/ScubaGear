package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.1.1v1
#--
test_AutoForwardEnabled_Correct if {
    Output := exo.tests with input.remote_domains as [RemoteDomains]

    TestResult("MS.EXO.1.1v1", Output, PASS, true) == true
}

test_AutoForwardEnabled_Incorrect_V1 if {

    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])

    Output := exo.tests with input.remote_domains as [Domain]

    ReportDetailString := "1 remote domain(s) that allows automatic forwarding: Test name"
    TestResult("MS.EXO.1.1v1", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V2 if {
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "Test name 2"}])

    
    Output := exo.tests with input.remote_domains as [Domain, Domain2]

    ReportDetailString := "2 remote domain(s) that allows automatic forwarding: Test name, Test name 2"
    TestResult("MS.EXO.1.1v1", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V3 if {

    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "Test name 2"}])
    Domain3 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": false},
                                            {"op": "add", "path": "DomainName", "value": "Test name 3"}])

    Output := exo.tests with input.remote_domains as [Domain, Domain2, Domain3]


    ReportDetailString := "2 remote domain(s) that allows automatic forwarding: Test name, Test name 2"
    TestResult("MS.EXO.1.1v1", Output, ReportDetailString, false) == true
}
#--