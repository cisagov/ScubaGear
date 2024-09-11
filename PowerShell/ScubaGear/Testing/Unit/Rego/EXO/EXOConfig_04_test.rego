package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.4.1v1
#--
test_Rdata_Correct if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecords]

    TestResult("MS.EXO.4.1v1", Output, PASS, true) == true
}

test_Rdata_Incorrect_V1 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": []}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.1v1", Output, ReportDetailStr, false) == true
}

test_Rdata_Incorrect_V2 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": ["v=DMARC1"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.1v1", Output, ReportDetailStr, false) == true
}

test_Rdata_Incorrect_V3 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "bad.name"}])
 
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": ["v=DMARC1"]},
                                                {"op": "add", "path": "domain", "value": "bad.name"}])
    
    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dmarc_records as [DmarcRecords, DmarcRecord1]


    ReportDetailStr := "1 agency domain(s) found in violation: bad.name"
    TestResult("MS.EXO.4.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.EXO.4.2v1
#--
test_Rdata_Correct_V2 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecords]

    TestResult("MS.EXO.4.2v1", Output, PASS, true) == true
}

test_Rdata_Incorrect_V4 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=none; mailto:reports@dmarc.cyber.dhs.gov mailto:jsmith@dhs.gov mailto:jsomething@dhs.gov"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.2v1", Output, ReportDetailStr, false) == true
}

test_Rdata_Incorrect_V5 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; mailto:reports@dmarc.cyber.dhs.gov mailto:jsmith@dhs.gov mailto:jsomething@dhs.gov"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.2v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.EXO.4.3v1
#--
test_DMARCReport_Correct_V1 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecords]


    TestResult("MS.EXO.4.3v1", Output, PASS, true) == true
}

test_DMARCReport_Incorrect_V1 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": ["v=DMARC1; p=reject; pct=100;"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.3v1", Output, ReportDetailStr, false) == true
}

test_DMARCReport_Incorrect_V2 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", 
                                                "value": ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@wrong.address"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.3v1", Output, ReportDetailStr, false) == true
}

# empty rdata
test_DMARCReport_Incorrect_V3 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": []}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.3v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.EXO.4.4v1
#--

# 2 emails in rua= and 1 in ruf
test_POC_Correct_V1 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov; ruf=agencyemail@hq.dhs.gov"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    TestResult("MS.EXO.4.4v1", Output, PASS, true) == true
}

# 2+ emails in rua= and 1+ in ruf
test_POC_Correct_V2 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov, mailto:test@example.com; ruf=agencyemail@hq.dhs.gov, test@test.com"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1] 

    TestResult("MS.EXO.4.4v1", Output, PASS, true) == true
}

# Only 1 rua
test_POC_Incorrect_V1 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1] 

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}

# Only 2 emails in rua no ruf
test_POC_Incorrect_V2 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, test@exo.com"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1] 

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}

# Only 1 ruf no rua
test_POC_Incorrect_V3 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=test@exo.com"]}])

    Output := exo.tests with input.spf_records as [SPFRecord]
                        with input.dmarc_records as [DmarcRecord1]

    ReportDetailStr := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}

# 2 domains 1 fails rua/ruf number
test_POC_Incorrect_V4 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.com"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, test@test.name ruf=test2@test.name"]}])
    DmarcRecord2 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov"]},
                                            {"op": "add", "path": "domain", "value": "example.com"}])
    
    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dmarc_records as [DmarcRecord1, DmarcRecord2]

    ReportDetailStr := "1 agency domain(s) found in violation: example.com"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}

# 2 domains 1 fails rua # of email policy requirement
test_POC_Incorrect_V5 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.com"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, test@test.name ruf=test2@test.name"]}])
    DmarcRecord2 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov; ruf=test@exo.com"]},
                                            {"op": "add", "path": "domain", "value": "example.com"}])
    
    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dmarc_records as [DmarcRecord1, DmarcRecord2]

    ReportDetailStr := "1 agency domain(s) found in violation: example.com"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}

# 2 domains 1 domain failed DNS query. Empty rdata
test_POC_Incorrect_V6 if {
    SPFRecord := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "test.name"}])
    SPFRecord1 := json.patch(SpfRecords, [{"op": "add", "path": "rdata", "value": ["spf1 "]},
                                        {"op": "add", "path": "domain", "value": "example.com"}])
    DmarcRecord1 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": 
                                                ["v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, test@test.name ruf=test2@test.name"]}])
    DmarcRecord2 := json.patch(DmarcRecords, [{"op": "add", "path": "rdata", "value": []},
                                        {"op": "add", "path": "domain", "value": "example.com"}])
    
    Output := exo.tests with input.spf_records as [SPFRecord, SPFRecord1]
                        with input.dmarc_records as [DmarcRecord1, DmarcRecord2]

    ReportDetailStr := "1 agency domain(s) found in violation: example.com"
    TestResult("MS.EXO.4.4v1", Output, ReportDetailStr, false) == true
}
#--