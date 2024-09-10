package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.EXO.2.2v2
#--
test_Rdata_Correct_V1 if {
    Output := exo.tests with input.spf_records as [SpfRecords]


    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Correct_V2 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["v=spf1 redirect"]}])
    
    Output := exo.tests with input.spf_records as [Record]

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Incorrect_V1 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]}])
    
    Output := exo.tests with input.spf_records as [Record]

    ReportDetailString := "1 agency domain(s) found in violation: Test name"
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
}

test_Rdata_Incorrect_V2 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": [""]}])
    
    Output := exo.tests with input.spf_records as [Record]
    
    ReportDetailString := "1 agency domain(s) found in violation: Test name"
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
}

# if we can make any assumptions about the order these domains
# will be printed in, hence the "contains" operator instead of ==
test_Rdata_Incorrect_V3 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["v=spf1 -all"]},
                                        {"op": "add", "path": "domain", "value": "good.com"}])
    Record2 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": [""]},
                                        {"op": "add", "path": "domain", "value": "bad.com"}])
    Record3 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": [""]},
                                        {"op": "add", "path": "domain", "value": "2bad.com"}])

    Output := exo.tests with input.spf_records as [Record, Record2, Record3]

    ReportDetailArrayStrs := [
        "2 agency domain(s) found in violation: ",
        "bad.com", # I'm not sure
        "2bad.com"
    ]
    TestResultContains("MS.EXO.2.2v2", Output, ReportDetailArrayStrs, false) == true
}

test_Rdata_Multiple_Correct_V1 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", 
                                        "value": ["v=spf1 -all", "extra stuff that shouldn't matter"]},
                                        {"op": "add", "path": "domain", "value": "good.com"}])

    Output := exo.tests with input.spf_records as [Record]

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Multiple_Correct_V2 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", 
                                        "value": ["extra stuff that shouldn't matter", "v=spf1 -all"]},
                                        {"op": "add", "path": "domain", "value": "good.com"}])

    Output := exo.tests with input.spf_records as [Record]

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Multiple_Correct_V3 if {
    # Test SPF redirect
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["v=spf1 redirect=_spf.example.com"]},
                                        {"op": "add", "path": "domain", "value": "test1.name"}])

    Output := exo.tests with input.spf_records as [Record]
                        with input.domains as ["test1.name"]

    TestResult("MS.EXO.2.2v2", Output, PASS, true) == true
}

test_Rdata_Multiple_Incorrect if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", 
                                        "value": ["extra stuff that shouldn't matter", "hello world"]},
                                        {"op": "add", "path": "domain", "value": "bad.com"}])

    Output := exo.tests with input.spf_records as [Record]

    ReportDetailString := "1 agency domain(s) found in violation: bad.com"
    TestResult("MS.EXO.2.2v2", Output, ReportDetailString, false) == true
}
#--