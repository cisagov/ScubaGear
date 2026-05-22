package utils.securitysuite

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

TenantDomainNames := Domains if {
    Domains := {
        lower(trim_space(Domain.DomainName)) |
        some Domain in input.accepted_domains
        Domain.DomainName != null
    }
} else := set()

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

CustomPolicyCoversAllRecipients(Policy) if {
    TenantDomains := TenantDomainNames
    count(TenantDomains) > 0
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
        count(TenantDomains - RuleDomains) == 0
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
    CustomPolicyCoversAllRecipients(Policy)
}

HasAcceptableUserProtectionAction(Policy) if {
    Action := lower(Policy.TargetedUserProtectionAction)
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
    }
    count(Compliant) > 0
    Result := {
        "Compliant": true,
        "Message": "",
        "Policies": Compliant,
    }
} else := {
    "Compliant": false,
    "Message": "No anti-phish policy that includes all partner domains.",
    "Policies": [],
}

default OrganizationDomainProtectionCompliant := false

OrganizationDomainProtectionCompliant := true if {
    some Policy in EnabledAntiPhishPolicies
    Policy.EnableOrganizationDomainsProtection == true
}
