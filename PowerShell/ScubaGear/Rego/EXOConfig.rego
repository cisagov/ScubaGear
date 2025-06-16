package exo
import rego.v1
import data.utils.report.DefenderMirrorDetails
import data.utils.report.ArraySizeStr
import data.utils.report.ReportDetailsBoolean
import data.utils.report.Description
import data.utils.report.ReportDetailsString
import data.utils.report.ReportDetailsArray
import data.utils.key.FilterArray


# this should be allowed https://github.com/StyraInc/regal/issues/415
# regal ignore:prefer-set-or-object-rule
AllDomains := {Domain.domain | some Domain in input.spf_records}


############
# MS.EXO.1 #
############

#
# MS.EXO.1.1v2
#--

# Loop through each domain & check if Auto Forwarding is enabled
# If enabled, save the domain in the RemoteDomainsAllowingForwarding array
RemoteDomainsAllowingForwarding contains Domain.DomainName if {
    some Domain in input.remote_domains
    Domain.AutoForwardEnabled == true
}

# Note explaining that the config option is available / warning if they misuse it
default NoticeAboutConfigFile := "" # No notice needed, the user knows about the config option and isn't misusing it
NoticeAboutConfigFile := Notice if {
    Domains := {Domain | some Domain in input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains}
    count(Domains) == 0
    Notice := concat("", [
        "NOTE: specific domains that have a legitimate need to allow remote forwarding can be configured in a ",
        "ScubaGear config file."
    ])
} else := Notice if {
    Domains := {Domain | some Domain in input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains}
    count(Domains) > 0
    "*" in Domains
    "*" in RemoteDomainsAllowingForwarding
    Notice := concat("", [
        "WARNING: the default domain, \"*\", was included in the 'AllowedForwardingDomains' list in the config file ",
        "but only specific domains can be allow-listed per the SCuBA baseline."
    ])
}

# Collect the set of domains that are allowed per the config file, excluding the default domain if needed
ConfiguredAllowedForwardingDomains := Domains-{"*"} if {
    Domains := {Domain | some Domain in input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains}
    "*" in Domains
} else := {Domain | some Domain in input.scuba_config.Exo["MS.EXO.1.1v2"].AllowedForwardingDomains}


# Get the domains allowing forwarding that haven't been allow-listed
NonCompForwardingDomains := RemoteDomainsAllowingForwarding - ConfiguredAllowedForwardingDomains

# Get the domains allowing forwarding that have been allow-listed
AllowedForwardingDomains := intersection({RemoteDomainsAllowingForwarding, ConfiguredAllowedForwardingDomains})

# Helper functions for pretty grammer
PluralDomains(N) := "domain" if N == 1 else := "domains"
PluralToBe(N) := "is" if N == 1 else := "are"
PluralAllow(N) := "allows" if N == 1 else := "allow"

# Sentence summarizing the non-compliant domains
NonCompDomainsSummary := concat("", [
    ArraySizeStr(NonCompForwardingDomains),
    " remote ",
    PluralDomains(count(NonCompForwardingDomains)),
    " ",
    PluralAllow(count(NonCompForwardingDomains)),
    " automatic forwarding: ",
    concat(", ", NonCompForwardingDomains),
    "."
])

# Sentence summarizing the domains that allow forwarding but have been allow-listed
AllowedDomainsSummary := concat("", [
    ArraySizeStr(AllowedForwardingDomains),
    " remote ",
    PluralDomains(count(AllowedForwardingDomains)),
    " ",
    PluralAllow(count(AllowedForwardingDomains)),
    " forwarding but ",
    PluralToBe(count(AllowedForwardingDomains)),
    " allowed per the ScubaGear config file: ",
    concat(", ", AllowedForwardingDomains),
    "."
])

# Details string for MS.EXO.1.1v2 that takes into account both the forwarding domains that have
# been allow-listed and the domains that have not
ReportDetails1_2 := Details if {
    count(NonCompForwardingDomains) == 0
    count(AllowedForwardingDomains) == 0
    Details := "No domains allow automatic forwarding."
} else := Details if {
    count(NonCompForwardingDomains) > 0
    count(AllowedForwardingDomains) > 0
    Details := concat(" ", [
        NonCompDomainsSummary,
        "NOTE: additionally,",
        AllowedDomainsSummary,
        NoticeAboutConfigFile
    ])
} else := Details if {
    count(NonCompForwardingDomains) > 0
    count(AllowedForwardingDomains) == 0
        Details := concat(" ", [
            NonCompDomainsSummary,
            NoticeAboutConfigFile
        ])
} else := Details if {
    # Note that even though this case is compliant, we still have valuable details we can present in the report
    count(NonCompForwardingDomains) == 0
    count(AllowedForwardingDomains) > 0
    Details := concat(" ", [AllowedDomainsSummary, NoticeAboutConfigFile])
}

tests contains {
    "PolicyId": "MS.EXO.1.1v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-RemoteDomain"],
    "ActualValue": {
        "RemoteDomainsAllowingForwarding": RemoteDomainsAllowingForwarding,
        "AllowedForwardingDomainsFromConfig": AllowedForwardingDomains
    },
    "ReportDetails": ReportDetails1_2,
    "RequirementMet": Status
} if {
    Status := count(NonCompForwardingDomains) == 0
}
#--


############
# MS.EXO.2 #
############

#
# MS.EXO.2.2v2
#--

# Loop through domains and save the details for domains without proper SPF records
DomainsWithoutSpf contains Details if {
    some DNSResponse in input.spf_records
    not DNSResponse.compliant
    Details := concat("", [
        "<li>",
        DNSResponse.domain,
        ": ",
        DNSResponse.message,
        "</li>"
    ])
}

# Link used for SPF, DKIM, and DMARC related logs
DNSLink = "<a href=\"#dns-logs\">View DNS logs</a> for more details."

SpfStatusMessage := Message if {
    count(DomainsWithoutSpf) == 0
    Message := "Requirement met"
} else := concat("", [
        format_int(count(DomainsWithoutSpf), 10),
        " failing domain(s):",
        "<ul>",
        concat("", DomainsWithoutSpf),
        "</ul>"
    ])

tests contains {
    "PolicyId": "MS.EXO.2.2v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-ScubaSpfRecord", "Get-AcceptedDomain"],
    "ActualValue": DomainsWithoutSpf,
    "ReportDetails": concat(". ", [SpfStatusMessage, DNSLink]),
    "RequirementMet": Status
} if {
    Status := count(DomainsWithoutSpf) == 0
}
#--


############
# MS.EXO.3 #
############

#
# MS.EXO.3.1v1
#--

# Loop through domain dkim configuration. If dkim is enabled,
# loop through dkim records. If the record is asscoiated with the same domain
# as the dkim config, loop through the rdata & save the record containing the
# string with "v=DKIM1;". If string exists, save domain name in DomainsWithDkim array.
DomainsWithDkim contains DkimConfig.Domain if {
    some DkimConfig in input.dkim_config
    DkimConfig.Enabled == true

    some DkimRecord in input.dkim_records
    DkimRecord.domain == DkimConfig.Domain
    ValidAnswers := [Answer | some Answer in DkimRecord.rdata; startswith(Answer, "v=DKIM1;")]
    count(ValidAnswers) > 0
}

tests contains {
    "PolicyId": "MS.EXO.3.1v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-DkimSigningConfig",
        "Get-ScubaDkimRecord",
        "Get-AcceptedDomain"
    ],
    "ActualValue": [input.dkim_records, input.dkim_config],
    "ReportDetails": concat(". ", [
        ReportDetailsArray(Status, DomainsWithoutDkim, "agency domain(s) found in violation:"),
        DNSLink
    ]),
    "RequirementMet": Status
} if {
    # Get domains that are not in DomainsWithDkim array
    DomainsWithoutDkim := AllDomains - DomainsWithDkim
    Status := count(DomainsWithoutDkim) == 0
}
#--


############
# MS.EXO.4 #
############

#
# MS.EXO.4.1v1
#--

# Loop through domain dmarc records. Parse each record's rdata for the
# string with "v=DMARC1;". If string does not exist, save domain name
# in DomainsWithoutDmarc array.
DomainsWithoutDmarc contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    ValidAnswers := [Answer | some Answer in DmarcRecord.rdata; startswith(Answer, "v=DMARC1;")]
    count(ValidAnswers) == 0
}

tests contains {
    "PolicyId": "MS.EXO.4.1v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-ScubaDmarcRecord",
        "Get-AcceptedDomain"
    ],
    "ActualValue": input.dmarc_records,
    "ReportDetails": concat(". ", [
        ReportDetailsArray(Status, Domains, "agency domain(s) found in violation:"),
        DNSLink
    ]),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutDmarc
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.2v1
#--

# Loop through domain dmarc records. Parse each record's rdata for the
# string with "p=reject;". If string does not exist, save domain name
# in DomainsWithoutPreject array.
DomainsWithoutPreject contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    ValidAnswers := [Answer | some Answer in DmarcRecord.rdata; contains(Answer, "p=reject;")]
    count(ValidAnswers) == 0
}

tests contains {
    "PolicyId": "MS.EXO.4.2v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-ScubaDmarcRecord",
        "Get-AcceptedDomain"
    ],
    "ActualValue": input.dmarc_records,
    "ReportDetails": concat(". ", [
        ReportDetailsArray(Status, Domains, "agency domain(s) found in violation:"),
        DNSLink
    ]),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutPreject
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.3v1
#--

# Loop through domain dmarc records. Parse each record's rdata & split
# string at ";". Parse the split string for substring that contains "rua=".
# Save substrings in RuaFields & check if "mailto:reports@dmarc.cyber.dhs.gov"
# is contained in RuaFields. Is email does not exist, save domain in
# DomainsWithoutDHSContact array.
DomainsWithoutDHSContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    some Rdata in DmarcRecord.rdata
    RuaFields := [Rua | some Rua in split(Rdata, ";"); contains(Rua, "rua=")]
    ValidAnswers := [Answer | some Answer in RuaFields; contains(Answer, "mailto:reports@dmarc.cyber.dhs.gov")]
    count(ValidAnswers) == 0
}

# Loop through domain dmarc records. if rdata does not exist,
# save domain in DomainsWithoutDHSContact array.
DomainsWithoutDHSContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests contains {
    "PolicyId": "MS.EXO.4.3v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-ScubaDmarcRecord",
        "Get-AcceptedDomain"
    ],
    "ActualValue": input.dmarc_records,
    "ReportDetails": concat(". ", [
        ReportDetailsArray(Status, Domains, "agency domain(s) found in violation:"),
        DNSLink
    ]),    "RequirementMet": Status
} if {
    Domains := DomainsWithoutDHSContact
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.4v1
#--

# Loop through domain dmarc records. Parse each record's rdata & split
# string at ";". Parse the split string for substring that contains "rua=".
# Save substrings in RuaFields. Parse the split string for substring that
# contains "ruf=". Save substrings in RufFields. Check RuaFields contain 2
# or more emails by spliting substring at "@" & save boolean result if any
# substrings pass in RuaCountAcceptable. Check RufFields contain 1 or more
# emails by spliting substring at "@" & save boolean result if any
# substrings pass in RufCountAcceptable. If RuaCountAcceptable OR
# RufCountAcceptable failed, save domain name in DomainsWithoutAgencyContact
# array.
DomainsWithoutAgencyContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    some Rdata in DmarcRecord.rdata
    DmarcFields := split(Rdata, ";")
    RuaFields := [Rua | some Rua in DmarcFields; contains(Rua, "rua=")]
    RufFields := [Ruf | some Ruf in DmarcFields; contains(Ruf, "ruf=")]

    # 2 or more emails including reports@dmarc.cyber.dhs.gov checked by policy 4.3
    RuaCountAcceptable := count([Answer | some Answer in RuaFields; count(split(Answer, "@")) > 2]) >= 1

    # 1 or more emails
    RufCountAcceptable := count([Answer | some Answer in RufFields; count(split(Answer, "@")) > 1]) >= 1
    Conditions := [
        RuaCountAcceptable,
        RufCountAcceptable
    ]
    count(FilterArray(Conditions, false)) > 0
}

# Loop through domain dmarc records. if rdata does not exist,
# save domain in DomainsWithoutDHSContact array.
DomainsWithoutAgencyContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests contains {
    "PolicyId": "MS.EXO.4.4v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-ScubaDmarcRecord",
        "Get-AcceptedDomain"
    ],
    "ActualValue": input.dmarc_records,
    "ReportDetails": concat(". ", [
        ReportDetailsArray(Status, Domains, "agency domain(s) found in violation:"),
        DNSLink
    ]),    "RequirementMet": Status
} if {
    Domains := DomainsWithoutAgencyContact
    Status := count(Domains) == 0
}
#--


############
# MS.EXO.5 #
############

#
# MS.EXO.5.1v1
#--

# Loop through email config & check if smtp client auth
# is not disabled. If so, save the name in SmtpClientAuthEnabled
# array.
SmtpClientAuthEnabled contains TransportConfig.Name if {
    some TransportConfig in input.transport_config
    TransportConfig.SmtpClientAuthenticationDisabled == false
}

tests contains {
    "PolicyId": "MS.EXO.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TransportConfig"],
    "ActualValue": input.transport_config,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(SmtpClientAuthEnabled) == 0
}
#--


############
# MS.EXO.6 #
############

#
# MS.EXO.6.1v1
#--

# Loop through saring policies, then loop through domains in the policy.
# if a domain is "*" & contains "Contacts", save the policy name in
# SharingPolicyContactsAllowedAllDomains array.
SharingPolicyContactsAllowedAllDomains contains SharingPolicy.Name if {
    some SharingPolicy in input.sharing_policy
    some Domains in SharingPolicy.Domains
    contains(Domains, "*")
    contains(Domains, "Contacts")
}

tests contains {
    "PolicyId": "MS.EXO.6.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SharingPolicy"],
    "ActualValue": input.sharing_policy,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ContactsSharingPolicies := SharingPolicyContactsAllowedAllDomains
    ErrString := "sharing polic(ies) are sharing contacts folders with all domains by default:"
    ErrMessage := Description([
        ArraySizeStr(ContactsSharingPolicies),
        ErrString ,
        concat(", ", ContactsSharingPolicies)
    ])
    Status := count(ContactsSharingPolicies) == 0
}
#--

#
# MS.EXO.6.2v1
#--

# Loop through saring policies, then loop through domains in the policy.
# if a domain is "*" & contains "Calendar", save the policy name in
# SharingPolicyCalendarAllowedAllDomains array.
SharingPolicyCalendarAllowedAllDomains contains SharingPolicy.Name if {
    some SharingPolicy in input.sharing_policy
    some Domains in SharingPolicy.Domains
    contains(Domains, "*")
    contains(Domains, "Calendar")
}

tests contains {
    "PolicyId": "MS.EXO.6.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SharingPolicy"],
    "ActualValue": input.sharing_policy,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    CalendarSharingPolicies := SharingPolicyCalendarAllowedAllDomains
    ErrString := "sharing polic(ies) are sharing calendar details with all domains by default:"
    ErrMessage := Description([
        ArraySizeStr(CalendarSharingPolicies),
        ErrString ,
        concat(", ", CalendarSharingPolicies)
    ])
    Status := count(CalendarSharingPolicies) == 0
}
#--


############
# MS.EXO.7 #
############

#
# MS.EXO.7.1v1
#--

# Loop through email rules, if rule is: enabled, set to enforce,
# & PrependSubject >= 1, then save rule in EnabledRules
EnabledRules contains Rule if {
    Rules := input.transport_rule
    some Rule in Rules;
    Rule.State == "Enabled";
    Rule.Mode == "Enforce";
    count(Rule.PrependSubject) >= 1
}

tests contains {
    "PolicyId": "MS.EXO.7.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TransportRule"],
    "ActualValue": [Rule.FromScope | some Rule in input.transport_rule],
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {

    ErrMessage := "No transport rule found that applies warnings to emails received from outside the organization"
    Conditions := [ (Rule.FromScope == "NotInOrganization") | some Rule in EnabledRules]
    Status := count(FilterArray(Conditions, true)) > 0
}
#--


############
# MS.EXO.8 #
############

#
# MS.EXO.8.1v2
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.1v2",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.1v2"),
    "RequirementMet": false
}
#--

#
# MS.EXO.8.2v2
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.2v2",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.2v2"),
    "RequirementMet": false
}
#--

#
# MS.EXO.8.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.3v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.8.4v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.4v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.4v1"),
    "RequirementMet": false
}
#--

############
# MS.EXO.9 #
############

#
# MS.EXO.9.1v2
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.1v2",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.1v2"),
    "RequirementMet": false
}
#--

#
# MS.EXO.9.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.2v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.9.3v2
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.3v2",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.3v2"),
    "RequirementMet": false
}
#--

#
# MS.EXO.9.4v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.4v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.4v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.9.5v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.5v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.5v1"),
    "RequirementMet": false
}
#--


#############
# MS.EXO.10 #
#############

#
# MS.EXO.10.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.1v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.10.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.2v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.10.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.3v1"),
    "RequirementMet": false
}
#--


#############
# MS.EXO.11 #
#############

#
# MS.EXO.11.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.1v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.11.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.2v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.11.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.3v1"),
    "RequirementMet": false
}
#--


#############
# MS.EXO.12 #
#############

#
# MS.EXO.12.1v1
#--

# Loop thorugh connection filter. If filter has an IP allow
# list, save the filter name to ConnFiltersWithIPAllowList array.
ConnFiltersWithIPAllowList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    count(ConnFilter.IPAllowList) > 0
}

tests contains {
    "PolicyId": "MS.EXO.12.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ConnFilterPolicies := ConnFiltersWithIPAllowList
    ErrString := "connection filter polic(ies) with an IP allowlist:"
    ErrMessage := Description([ArraySizeStr(ConnFilterPolicies), ErrString , concat(", ", ConnFilterPolicies)])
    Status := count(ConnFilterPolicies) == 0
}
#--

#
# MS.EXO.12.2v1
#--

# Loop thorugh connection filter. If filter has safe
# list enabled, save filter name to ConnFiltersWithSafeList
# array.
ConnFiltersWithSafeList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    ConnFilter.EnableSafeList == true
}

tests contains {
    "PolicyId": "MS.EXO.12.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ConnFilterPolicies := ConnFiltersWithSafeList
    ErrString := "connection filter polic(ies) with a safe list:"
    ErrMessage := Description([ArraySizeStr(ConnFilterPolicies), ErrString , concat(", ", ConnFilterPolicies)])
    Status := count(ConnFilterPolicies) == 0
}
#--


#############
# MS.EXO.13 #
#############

#
# MS.EXO.13.1v1
#--

# Loop for organization config. If Audit is disabled,
# Save the config name in AuditDisabled array.
AuditDisabled contains OrgConfig.Name if {
    some OrgConfig in input.org_config
    OrgConfig.AuditDisabled == true
}

tests contains {
    "PolicyId": "MS.EXO.13.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-OrganizationConfig"],
    "ActualValue": input.org_config,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(AuditDisabled) == 0
}
#--


#############
# MS.EXO.14 #
#############

#
# MS.EXO.14.1v2
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.1v2",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.1v2"),
    "RequirementMet": false
}
#--

#
# MS.EXO.14.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.2v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.14.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.3v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.3v1"),
    "RequirementMet": false
}
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.4v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.4v1"),
    "RequirementMet": false
}
#--

#############
# MS.EXO.15 #
#############

#
# MS.EXO.15.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.1v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.15.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.2v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.15.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.3v1"),
    "RequirementMet": false
}
#--


#############
# MS.EXO.16 #
#############

#
# MS.EXO.16.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.16.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.16.1v1"),
    "RequirementMet": false
}
#--

#
# MS.EXO.16.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.16.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.16.2v1"),
    "RequirementMet": false
}
#--


#############
# MS.EXO.17 #
#############

#
# MS.EXO.17.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.17.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.17.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.17.3v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.17.3v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.17.3v1"),
    "RequirementMet": false
}
#--