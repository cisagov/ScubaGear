package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult


#
# Policy MS.EXO.1.1v2
#--

NoteAboutConfig := concat("", [
    "NOTE: specific domains that have a legitimate need to allow remote forwarding can be configured in a ScubaGear ",
    "config file."
])

WarningAboutDefaultDomain := concat("", [
    "WARNING: the default domain, \"*\", was included in the 'AllowedForwardingDomains' list in the config file but ",
    "only specific domains can be allow-listed per the SCuBA baseline."
])

test_AutoForwardEnabled_Correct_V1 if {
    # No domains allow forwarding
    Output := exo.tests with input.remote_domains as [RemoteDomains]

    ReportDetailString := "No domains allow automatic forwarding."
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, true) == true
}

test_AutoForwardEnabled_Correct_V2 if {
    # One domain allows forwarding but has been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])

    Output := exo.tests with input.remote_domains as [Domain]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["example.com"]

    ReportDetailString :=
        "1 remote domain allows forwarding but is allowed per the ScubaGear config file: example.com. "
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, true) == true
}

test_AutoForwardEnabled_Correct_V3 if {
    # Two domains allow forwarding but has been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example2.com"}])

    Output := exo.tests with input.remote_domains as [Domain, Domain2]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["example.com", "example2.com"]

    ReportDetailString :=
        "2 remote domains allow forwarding but are allowed per the ScubaGear config file: example.com, example2.com. "

    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, true) == true
}

test_AutoForwardEnabled_Correct_V4 if {
    # No domains allow forwarding but several domains were still allow-listed
    Output := exo.tests with input.remote_domains as [RemoteDomains]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["*", "example.com", "example2.com"]

    ReportDetailString := "No domains allow automatic forwarding."

    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, true) == true
}

test_AutoForwardEnabled_Incorrect_V1 if {
    # 1 domain allows forwarding and hasn't been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])

    Output := exo.tests with input.remote_domains as [Domain]
    ReportDetailString := concat(" ", ["1 remote domain allows automatic forwarding: example.com.", NoteAboutConfig])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V2 if {
    # 2 domains allow forwarding and haven't been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example2.com"}])


    Output := exo.tests with input.remote_domains as [Domain, Domain2]
    ReportDetailString := concat(" ", [
        "2 remote domains allow automatic forwarding: example.com, example2.com.",
        NoteAboutConfig
    ])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V3 if {
    # 2 domains allow forwarding but one has been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example2.com"}])

    Output := exo.tests with input.remote_domains as [Domain, Domain2]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["example.com"]

    ReportDetailString := concat(" ", [
        "1 remote domain allows automatic forwarding: example2.com.",
        "NOTE: additionally, 1 remote domain allows forwarding but is allowed per the ScubaGear config file:",
        "example.com. "
    ])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V4 if {
    # 4 domains allow forwarding but two have been allow-listed
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example2.com"}])
    Domain3 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example3.com"}])
    Domain4 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "example4.com"}])

    Output := exo.tests with input.remote_domains as [Domain, Domain2, Domain3, Domain4]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["example.com", "example2.com"]

    ReportDetailString := concat(" ", [
        "2 remote domains allow automatic forwarding: example3.com, example4.com.",
        "NOTE: additionally, 2 remote domains allow forwarding but are allowed per the ScubaGear config file:",
        "example.com, example2.com. "
    ])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V5 if {
    # User attempts to allow-list the default domain ("*")
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "*"}])


    Output := exo.tests with input.remote_domains as [Domain]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["*"]

    ReportDetailString := concat(" ", ["1 remote domain allows automatic forwarding: *.", WarningAboutDefaultDomain])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}

test_AutoForwardEnabled_Incorrect_V6 if {
    # User attempts to allow-list the default domain ("*") and also allow-lists a different domain.
    Domain := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true}])
    Domain2 := json.patch(RemoteDomains, [{"op": "add", "path": "AutoForwardEnabled", "value": true},
                                            {"op": "add", "path": "DomainName", "value": "*"}])


    Output := exo.tests with input.remote_domains as [Domain, Domain2]
        with input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains as ["*", "example.com"]

    ReportDetailString := concat("", [
        "1 remote domain allows automatic forwarding: *. NOTE: additionally, 1 remote domain allows forwarding but is ",
        "allowed per the ScubaGear config file: example.com. ",
        WarningAboutDefaultDomain
    ])
    TestResult("MS.EXO.1.1v2", Output, ReportDetailString, false) == true
}
#--