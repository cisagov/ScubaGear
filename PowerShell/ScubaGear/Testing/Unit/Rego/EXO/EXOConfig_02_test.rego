package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS
import data.exo.DNSLink

#
# Policy MS.EXO.2.2v2
#--
test_Spf_Correct_V1 if {
    # Test "good" case
    Output := exo.tests with input.spf_records as [SpfRecords]

    TestResult("MS.EXO.2.2v2", Output, concat(". ", [PASS, DNSLink]), true) == true
}

test_Spf_Incorrect_V1 if {
    # Test 1 bad domain
    Message := "SPF record found, but it does not hardfail (\"-all\") or redirect to one that does."
    Record := json.patch(SpfRecords, [
        {"op": "add", "path": "compliant", "value": false},
        {"op": "add", "path": "message", "value": Message}
    ])

    Output := exo.tests with input.spf_records as [Record]
    RuleOutput := [Result | some Result in Output; Result.PolicyId == "MS.EXO.2.2v2"]
    ReportDetailString := concat("", [
        "1 failing domain(s):<ul id=\"spf-domains\">",
        "<li>test.name: ",
        Message,
        "</li>",
        "</ul>"
    ])
    TestResult("MS.EXO.2.2v2", RuleOutput, concat(". ", [ReportDetailString, DNSLink]), false) == true
}

test_Spf_Incorrect_V2 if {
    # Test with 2 bad domains and one good domain
    Message1 := "SPF record found, but it does not hardfail (\"-all\") or redirect to one that does."
    Record1 := json.patch(SpfRecords, [
        {"op": "add", "path": "domain", "value": "bad1.com"},
        {"op": "add", "path": "compliant", "value": false},
        {"op": "add", "path": "message", "value": Message1}
    ])
    Message2 := "SPF record found, but it does not hardfail (\"-all\") or redirect to one that does."
    Record2 := json.patch(SpfRecords, [
        {"op": "add", "path": "domain", "value": "bad2.com"},
        {"op": "add", "path": "compliant", "value": false},
        {"op": "add", "path": "message", "value": Message2}
    ])
    Record3 := json.patch(SpfRecords, [
        {"op": "add", "path": "doamin", "value": "good1.com"},
        {"op": "add", "path": "compliant", "value": true},
        {"op": "add", "path": "message", "value": "SPF record found."}
    ])

    Output := exo.tests with input.spf_records as [Record1, Record2, Record3]
    RuleOutput := [Result | some Result in Output; Result.PolicyId == "MS.EXO.2.2v2"]
    ReportDetailString := concat("", [
        "2 failing domain(s):<ul id=\"spf-domains\">",
        "<li>bad1.com: ",
        Message1,
        "</li>",
        "<li>bad2.com: ",
        Message2,
        "</li>",
        "</ul>"
    ])
    TestResult("MS.EXO.2.2v2", RuleOutput, concat(". ", [ReportDetailString, DNSLink]), false) == true
}
#--