package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.3.1v1
#--
test_Enabled_Correct_V1 if {
    Record := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    Output := exo.tests with input.spf_records as [Record]
                        with input.dkim_config as [DkimConfig]
                        with input.dkim_records as [DkimRecords]

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
}

# Test with correct default domain
test_Enabled_Correct_V2 if {
    
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Domain", "value": "example.onmicrosoft.com"}])
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "domain", "value": "example.onmicrosoft.com"}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.onmicrosoft.com"}])

    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dkim_config as [DkimConfig, DkimConfig1]
                        with input.dkim_records as [DkimRecords, DkimRecord1]

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
}

# Test for multiple custom domains
test_Enabled_Correct_V3 if {
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Domain", "value": "test2.name"}])
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "domain", "value": "test2.name"}])
    
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test2.name"}])
    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dkim_config as [DkimConfig, DkimConfig1]
                        with input.dkim_records as [DkimRecords, DkimRecord1]


    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
}

# Test for no custom domains, just the default domain
test_Enabled_Correct_V4 if {
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Domain", "value": "example.onmicrosoft.com"}])
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "domain", "value": "example.onmicrosoft.com"}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.onmicrosoft.com"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dkim_config as [DkimConfig1]
                        with input.dkim_records as [DkimRecord1]


    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
}

test_Enabled_Incorrect if {
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Enabled", "value": false}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dkim_config as [DkimConfig1]
                        with input.dkim_records as [DkimRecords]


    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}

test_Rdata_Incorrect_V1 if {
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "rdata", "value": []}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dkim_config as [DkimConfig]
                        with input.dkim_records as [DkimRecord1]

    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}

test_Rdata_Incorrect_V2 if {
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "rdata", "value": ["hello world"]}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dkim_config as [DkimConfig]
                        with input.dkim_records as [DkimRecord1]

    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}

test_Enabled_Incorrect_V3 if {
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Domain", "value": "test2.name"},
                                            {"op": "add", "path": "Enabled", "value": false}])
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "domain", "value": "test2.name"}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord2 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test2.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord2]
                        with input.dkim_config as [DkimConfig, DkimConfig1]
                        with input.dkim_records as [DkimRecords, DkimRecord1]


    ReportDetailString := "1 agency domain(s) found in violation: test2.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}

# Test with incorrect default domain
test_Enabled_Incorrect_V4 if {
    DkimConfig1 := json.patch(DkimConfig, [{"op": "add", "path": "Domain", "value": "example.onmicrosoft.com"},
                                            {"op": "add", "path": "Enabled", "value": false}])
    DkimRecord1 := json.patch(DkimRecords, [{"op": "add", "path": "domain", "value": "example.onmicrosoft.com"},
                                            {"op": "add", "path": "rdata", "value": []}])
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord2 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.onmicrosoft.com"}])

    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord2]
                        with input.dkim_config as [DkimConfig, DkimConfig1]
                        with input.dkim_records as [DkimRecords, DkimRecord1]

    ReportDetailString := "1 agency domain(s) found in violation: example.onmicrosoft.com"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}
#--