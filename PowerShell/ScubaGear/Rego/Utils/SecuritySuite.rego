package utils.securitysuite

import data.utils.defender.ApplyLicenseWarningString
import data.utils.defender.DEFLICENSEWARNSTR
import data.utils.key.ConvertToSet
import rego.v1

#############################
# Config (SecuritySuite + Defender alias)
#############################

DEFENDER_POLICY_ALIASES := {
    "MS.SECURITYSUITE.2.1v1": "MS.DEFENDER.2.1v1",
    "MS.SECURITYSUITE.2.3v1": "MS.DEFENDER.2.3v1",
}

PolicyConfigSection(PolicyID) := Section if {
    Section := input.scuba_config.SecuritySuite[PolicyID]
}

else := Section if {
    AliasID := DEFENDER_POLICY_ALIASES[PolicyID]
    Section := input.scuba_config.Defender[AliasID]
}

else := {}

ListConfigValues(PolicyID, ListKey) := Values if {
    Section := PolicyConfigSection(PolicyID)
    Values := {
        Normalized |
        some Raw in Section[ListKey]
        Raw != null
        Normalized := NormalizeListEntry(Raw)
        Normalized != ""
    }
} else := set()

##############################################
# Impersonation protection — shared helpers
##############################################

# https://learn.microsoft.com/en-us/powershell/module/exchange/set-antiphishpolicy
UNACCEPTABLE_USER_PROTECTION_ACTIONS := {
    "noaction",
    "bccmessage",
}

TenantDomainNames contains lower(trim_space(Domain.DomainName)) if {
    some Domain in input.accepted_domains
    Domain.DomainName != null
}

IsPresetAntiPhishPolicy(Identity) if {
    regex.match(`(?i)Standard Preset Security Policy`, Identity)
}

IsPresetAntiPhishPolicy(Identity) if {
    regex.match(`(?i)Strict Preset Security Policy`, Identity)
}

RuleFieldEmpty(null)

RuleFieldEmpty(Value) if {
    count(Value) == 0
}

# Standard/Strict preset EOP rules: all recipients when SentTo, SentToMemberOf,
# and RecipientDomainIs are empty (same pattern as MS.DEFENDER.1.2v1).
PresetPolicyCoversAllRecipients(Identity) if {
    count([
        Rule |
        some Rule in input.protection_policy_rules
        regex.match(Identity, Rule.Identity)
        Rule.State == "Enabled"
        RuleFieldEmpty(Rule.SentTo)
        RuleFieldEmpty(Rule.SentToMemberOf)
        RuleFieldEmpty(Rule.RecipientDomainIs)
    ]) > 0
}

AntiPhishRuleForPolicy(Rule, Policy) if {
    Rule.State == "Enabled"
    Rule.AntiPhishPolicy == Policy.Name
}

AntiPhishRuleForPolicy(Rule, Policy) if {
    Rule.State == "Enabled"
    Rule.AntiPhishPolicy == Policy.Identity
}

CustomAntiPhishPolicyCoversAllRecipients(Policy) if {
    count(TenantDomainNames) > 0
    count([
        Rule |
        some Rule in input.anti_phish_rules
        AntiPhishRuleForPolicy(Rule, Policy)
        RuleFieldEmpty(Rule.SentTo)
        RuleFieldEmpty(Rule.SentToMemberOf)
        RuleFieldEmpty(Rule.ExceptIfSentTo)
        RuleFieldEmpty(Rule.ExceptIfSentToMemberOf)
        RuleFieldEmpty(Rule.ExceptIfRecipientDomainIs)
        RuleDomains := ConvertToSet(Rule.RecipientDomainIs)
        count(TenantDomainNames - RuleDomains) == 0
    ]) > 0
}

AntiPhishPolicyCoversAllRecipients(Policy) if {
    Policy.IsDefault == true
}

AntiPhishPolicyCoversAllRecipients(Policy) if {
    regex.match(`(?i)Standard Preset Security Policy`, Policy.Identity)
    PresetPolicyCoversAllRecipients(`(?i)Standard Preset Security Policy`)
}

AntiPhishPolicyCoversAllRecipients(Policy) if {
    regex.match(`(?i)Strict Preset Security Policy`, Policy.Identity)
    PresetPolicyCoversAllRecipients(`(?i)Strict Preset Security Policy`)
}

AntiPhishPolicyCoversAllRecipients(Policy) if {
    not Policy.IsDefault == true
    not IsPresetAntiPhishPolicy(Policy.Identity)
    CustomAntiPhishPolicyCoversAllRecipients(Policy)
}

HasAcceptableUserProtectionAction(Policy) if {
    Action := lower(Policy.TargetedUserProtectionAction)
    not Action in UNACCEPTABLE_USER_PROTECTION_ACTIONS
}

HasAcceptableDomainProtectionAction(Policy) if {
    Action := lower(Policy.TargetedDomainProtectionAction)
    not Action in UNACCEPTABLE_USER_PROTECTION_ACTIONS
}

NormalizeListEntry(Raw) := Normalized if {
    is_string(Raw)
    Normalized := lower(trim_space(Raw))
}

# SensitiveUsers: accept "Display Name;email@domain.com" or email-only.
SensitiveUserConfigEmails(ConfigUsers) := {Email |
    some Entry in ConfigUsers
    Email := SensitiveUserEmail(Entry)
}

SensitiveUserEmail(Entry) := Email if {
    Parts := split(Entry, ";")
    count(Parts) > 1
    Email := lower(trim_space(Parts[1]))
    Email != ""
}

SensitiveUserEmail(Entry) := Entry if {
    Parts := split(Entry, ";")
    count(Parts) == 1
}

PolicyProtectedUserEmails(Policy) := {Email |
    some Raw in Policy.TargetedUsersToProtect
    Entry := lower(trim_space(Raw))
    Email := SensitiveUserEmail(Entry)
}

PolicyIncludesAllSensitiveUsers(Policy, ConfigUsers) if {
    PolicyEmails := PolicyProtectedUserEmails(Policy)
    count(PolicyEmails) > 0
    ConfigEmails := SensitiveUserConfigEmails(ConfigUsers)
    count(ConfigEmails - PolicyEmails) == 0
}

EnabledAntiPhishPolicies contains Policy if {
    some Policy in input.anti_phish_policies
    Policy.Enabled == true
}

UserImpersonationCompliant(ConfigUsers) := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableTargetedUserProtection == true
        PolicyIncludesAllSensitiveUsers(PhishPolicy, ConfigUsers)
        HasAcceptableUserProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    count(Compliant) > 0
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": Compliant,
    }
} else := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableTargetedUserProtection == true
        PolicyIncludesAllSensitiveUsers(PhishPolicy, ConfigUsers)
        HasAcceptableUserProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    Partial := [Entry |
        some Policy in EnabledAntiPhishPolicies
        Policy.EnableTargetedUserProtection == true
        PolicyIncludesAllSensitiveUsers(Policy, ConfigUsers)
        HasAcceptableUserProtectionAction(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(Compliant) == 0
    count(Partial) == 1
    PartialPolicy := Partial[0]
    Result := {
        "Compliant": false,
        "Message": concat(" ", [
            sprintf("1 anti-phish policy found that includes all sensitive users ('%v'),", [PartialPolicy.Name]),
            "but not all users have been added as recipients.",
        ]),
        "Policies": Partial,
    }
} else := {
    "Compliant": false,
    "Message": "No anti-phish policy that includes all sensitive users.",
    "Policies": [],
}

PartnerDomainConfig(PolicyID) := ListConfigValues(PolicyID, "PartnerDomains")

PolicyProtectedDomains(Policy) := {lower(trim_space(x)) |
    some x in Policy.TargetedDomainsToProtect
    x != null
}

PolicyIncludesAllPartnerDomains(Policy, ConfigDomains) if {
    PolicyDomains := PolicyProtectedDomains(Policy)
    count(PolicyDomains) > 0
    count(ConfigDomains - PolicyDomains) == 0
}

PartnerDomainImpersonationCompliant(ConfigDomains) := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableTargetedDomainsProtection == true
        PolicyIncludesAllPartnerDomains(PhishPolicy, ConfigDomains)
        HasAcceptableDomainProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    count(Compliant) > 0
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": Compliant,
    }
} else := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableTargetedDomainsProtection == true
        PolicyIncludesAllPartnerDomains(PhishPolicy, ConfigDomains)
        HasAcceptableDomainProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    Partial := [Entry |
        some Policy in EnabledAntiPhishPolicies
        Policy.EnableTargetedDomainsProtection == true
        PolicyIncludesAllPartnerDomains(Policy, ConfigDomains)
        HasAcceptableDomainProtectionAction(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(Compliant) == 0
    count(Partial) == 1
    PartialPolicy := Partial[0]
    Result := {
        "Compliant": false,
        "Message": concat(" ", [
            sprintf("1 anti-phish policy found that includes all partner domains ('%v'),", [PartialPolicy.Name]),
            "but not all users have been added as recipients.",
        ]),
        "Policies": Partial,
    }
} else := {
    "Compliant": false,
    "Message": "No anti-phish policy that includes all partner domains, all recipients, and has an appropriate domain impersonation action.",
    "Policies": [],
}

default OrganizationDomainProtectionCompliant := {
    "Compliant": false,
    "Message": "No anti-phish policy has 'Include domains I own' enabled, includes all recipients, and has an appropriate domain impersonation action.",
    "Policies": [],
}

OrganizationDomainProtectionCompliant := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableOrganizationDomainsProtection == true
        HasAcceptableDomainProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    count(Compliant) > 0
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": Compliant,
    }
} else := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableOrganizationDomainsProtection == true
        HasAcceptableDomainProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    Partial := [Entry |
        some Policy in EnabledAntiPhishPolicies
        Policy.EnableOrganizationDomainsProtection == true
        HasAcceptableDomainProtectionAction(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(Compliant) == 0
    count(Partial) == 1
    PartialPolicy := Partial[0]
    Result := {
        "Compliant": false,
        "Message": concat(" ", [
            sprintf("1 anti-phish policy found that has 'Include domains I own' enabled ('%v'),", [PartialPolicy.Name]),
            "but not all users have been added as recipients.",
        ]),
        "Policies": Partial,
    }
} else := Result if {
    Compliant := {PhishPolicy |
        some PhishPolicy in EnabledAntiPhishPolicies
        PhishPolicy.EnableOrganizationDomainsProtection == true
        HasAcceptableDomainProtectionAction(PhishPolicy)
        AntiPhishPolicyCoversAllRecipients(PhishPolicy)
    }
    Partial := [Entry |
        some Policy in EnabledAntiPhishPolicies
        Policy.EnableOrganizationDomainsProtection == true
        HasAcceptableDomainProtectionAction(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(Compliant) == 0
    count(Partial) > 1
    Result := {
        "Compliant": false,
        "Message": "No anti-phish policy has 'Include domains I own' enabled for all recipients.",
        "Policies": Partial,
    }
}

##############################################
# User warnings / safety tips (2.4) helpers  #
##############################################

default PresetRecipientsCovered := false

PresetRecipientsCovered := true if {
    PresetPolicyCoversAllRecipients(`(?i)Standard Preset Security Policy`)
}

PresetRecipientsCovered := true if {
    PresetPolicyCoversAllRecipients(`(?i)Strict Preset Security Policy`)
}

HasSafetyTipsEnabled(Policy) if {
    Policy.EnableFirstContactSafetyTips == true
    Policy.EnableSimilarUsersSafetyTips == true
    Policy.EnableSimilarDomainsSafetyTips == true
    Policy.EnableUnusualCharactersSafetyTips == true
    Policy.EnableViaTag == true
    Policy.EnableUnauthenticatedSender == true
}

CustomSafetyTipsPolicies contains Policy if {
    some Policy in EnabledAntiPhishPolicies
    not IsPresetAntiPhishPolicy(Policy.Identity)
    HasSafetyTipsEnabled(Policy)
    AntiPhishPolicyCoversAllRecipients(Policy)
}

default UserWarningsCompliant := {
    "Compliant": false,
    "Message": "No anti-phish policy applies safety tips to all recipients.",
    "Policies": [],
}

UserWarningsCompliant := Result if {
    count(CustomSafetyTipsPolicies) > 0
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": CustomSafetyTipsPolicies,
    }
} else := Result if {
    PresetRecipientsCovered == true
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": set(),
    }
} else := Result if {
    PartialRecipients := [Entry |
        some Policy in EnabledAntiPhishPolicies
        not IsPresetAntiPhishPolicy(Policy.Identity)
        HasSafetyTipsEnabled(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(PartialRecipients) == 1
    PartialPolicy := PartialRecipients[0]
    Result := {
        "Compliant": false,
        "Message": concat(" ", [
            sprintf("1 anti-phish policy found with all safety tips enabled ('%v'),", [PartialPolicy.Name]),
            "but not all users have been added as recipients.",
        ]),
        "Policies": PartialRecipients,
    }
} else := Result if {
    PartialRecipients := [Entry |
        some Policy in EnabledAntiPhishPolicies
        not IsPresetAntiPhishPolicy(Policy.Identity)
        HasSafetyTipsEnabled(Policy)
        not AntiPhishPolicyCoversAllRecipients(Policy)
        Entry := {
            "Name": Policy.Identity,
            "MissingRecipients": true,
        }
    ]
    count(PartialRecipients) > 1
    Result := {
        "Compliant": false,
        "Message": "No anti-phish policy applies safety tips to all recipients.",
        "Policies": PartialRecipients,
    }
}

##############################################
# Defender license (policy group 2) helpers  #
##############################################

# Impersonation and safety-tip policies require Defender for Office 365 Plan 1
# or 2. Without it, automated results are not reliable; report a license warning
# and do not pass the requirement.
ImpersonationProtectionRequirementMet(_) := false if {
    input.defender_license == false
}

ImpersonationProtectionRequirementMet(Status) := Status if {
    input.defender_license == true
}

ImpersonationProtectionReportDetails(_, _) := DEFLICENSEWARNSTR if {
    input.defender_license == false
}

ImpersonationProtectionReportDetails(Status, Message) := ApplyLicenseWarningString(Status, Message) if {
    input.defender_license == true
}
