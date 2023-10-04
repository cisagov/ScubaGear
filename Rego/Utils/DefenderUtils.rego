package defender.utils
import future.keywords

##########################################
# User/Group Exclusion support functions #
##########################################

# Gets Sensitive Account Filter specification from SCuBA config input
SensitiveAccountsConfig(PolicyID) := {
    "IncludedUsers" : IncludedUsers,
    "ExcludedUsers" : ExcludedUsers,
    "IncludedGroups" : IncludedGroups,
    "ExcludedGroups" : ExcludedGroups,
    "IncludedDomains" : IncludedDomains,
    "ExcludedDomains" : ExcludedDomains
} {
    SensitiveAccounts := input.scuba_config.Defender[PolicyID].SensitiveAccounts
    IncludedUsers := { trim_space(x) | some x in SensitiveAccounts.IncludedUsers; x != null }
    ExcludedUsers := { trim_space(x) | some x in SensitiveAccounts.ExcludedUsers; x != null }
    IncludedGroups := { trim_space(x) | some x in SensitiveAccounts.IncludedGroups; x != null }
    ExcludedGroups := { trim_space(x) | some x in SensitiveAccounts.ExcludedGroups; x != null }
    IncludedDomains := { trim_space(x) | some x in SensitiveAccounts.IncludedDomains; x != null }
    ExcludedDomains := { trim_space(x) | some x in SensitiveAccounts.ExcludedDomains; x != null }
} else := {
    "IncludedUsers" : set(),
    "ExcludedUsers" : set(),
    "IncludedGroups" : set(),
    "ExcludedGroups" : set(),
    "IncludedDomains" : set(),
    "ExcludedDomains" : set()
}

# Gets Sensitive Account Filter specified in policy input
SensitiveAccountsSetting(Policies) := {
    "IncludedUsers" : IncludedUsers,
    "ExcludedUsers" : ExcludedUsers,
    "IncludedGroups" : IncludedGroups,
    "ExcludedGroups" : ExcludedGroups,
    "IncludedDomains" : IncludedDomains,
    "ExcludedDomains" : ExcludedDomains,
    "Policy" : Policy[0]
} {
    Policy := [ Policy | Policy := Policies[_]; Policy.Identity == "Strict Preset Security Policy"; Policy.State == "Enabled" ]
    IncludedUsers := { x | x := Policy[0].SentTo[_] }
    ExcludedUsers := { x | x := Policy[0].ExceptIfSentTo[_] }
    IncludedGroups := { x | x := Policy[0].SentToMemberOf[_] }
    ExcludedGroups := { x | x := Policy[0].ExceptIfSentToMemberOf[_] }
    IncludedDomains := { x | x := Policy[0].RecipientDomainIs[_] }
    ExcludedDomains := { x | x := Policy[0].ExceptIfRecipientDomainIs[_] }
}

default SensitiveAccounts(_, _) := false
### Case 1 - No Strict Policy assignment ###
# Is there a Strict Policy present, if not always fail
SensitiveAccounts(SensitiveAccountsSetting, _) := false if {
    count(SensitiveAccountsSetting.Policy) == 0
}

### Case 2 ###
# Is there a Strict Policy present and no assignment conditions or exceptions, all users included. Always pass
SensitiveAccounts(SensitiveAccountsSetting, _) := true if {
    count(SensitiveAccountsSetting.Policy) > 0
    SensitiveAccountsSetting.Policy.Conditions == null
    SensitiveAccountsSetting.Policy.Exceptions == null
}

### Case 3 ###
# Is there a Strict Policy present and assignment conditions, but no include config.  Always fail
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := false if {
    count(SensitiveAccountsSetting.Policy) > 0

    # Policy filter includes one or more conditions or exclusions
    ConditionsAbsent := [
        SensitiveAccountsSetting.Policy.Conditions == null,
        SensitiveAccountsSetting.Policy.Exceptions == null
    ]
    count([x | x := ConditionsAbsent[_]; x == false]) > 0

    # No config is defined
    count(
        SensitiveAccountsConfig.IncludedUsers   |
        SensitiveAccountsConfig.ExcludedUsers   |
        SensitiveAccountsConfig.IncludedGroups  |
        SensitiveAccountsConfig.ExcludedGroups  |
        SensitiveAccountsConfig.IncludedDomains |
        SensitiveAccountsConfig.ExcludedDomains
        ) == 0
}

### Case 4 ###
# When settings and config are present, do they match?
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) > 0

    # Policy filter includes one or more conditions or exclusions
    ConditionsAbsent := [
        SensitiveAccountsSetting.Policy.Conditions == null,
        SensitiveAccountsSetting.Policy.Exceptions == null
    ]
    count([x | x := ConditionsAbsent[_]; x == false]) > 0

    # Config is defined
    count(
        SensitiveAccountsConfig.IncludedUsers   |
        SensitiveAccountsConfig.ExcludedUsers   |
        SensitiveAccountsConfig.IncludedGroups  |
        SensitiveAccountsConfig.ExcludedGroups  |
        SensitiveAccountsConfig.IncludedDomains |
        SensitiveAccountsConfig.ExcludedDomains
        ) > 0

    # All filter and config file settings mismatches
    Mismatches := [
        SensitiveAccountsSetting.IncludedUsers == SensitiveAccountsConfig.IncludedUsers,
        SensitiveAccountsSetting.IncludedGroups == SensitiveAccountsConfig.IncludedGroups,
        SensitiveAccountsSetting.IncludedDomains == SensitiveAccountsConfig.IncludedDomains,
        SensitiveAccountsSetting.ExcludedUsers == SensitiveAccountsConfig.ExcludedUsers,
        SensitiveAccountsSetting.ExcludedGroups == SensitiveAccountsConfig.ExcludedGroups,
        SensitiveAccountsSetting.ExcludedDomains == SensitiveAccountsConfig.ExcludedDomains
    ]
    count([x | x := Mismatches[_]; x == false]) == 0
}

##############################################
# Impersonation protection support functions #
##############################################

ImpersonationProtectionSetting(Policies, IdentityString, KeyValue) := Policy[0] if {
    Policy := [
        Policy | some Policy in Policies
        regex.match(IdentityString, Policy.Identity) == true
        Policy.Enabled == true
        Policy[KeyValue] == true
    ]
} else := set()

ImpersonationProtectionConfig(PolicyID, AccountKey) := IncludedAccounts if {
    SensitiveAccounts := input.scuba_config.Defender[PolicyID]
    IncludedAccounts := { lower(trim_space(x)) | some x in SensitiveAccounts[AccountKey]; x != null }
} else := set()

ImpersonationProtection(Policies, IdentityString, IncludedAccounts, FilterKey, AccountKey, ActionKey) := {
    "Result": true,
    "Policy": {
        "Name": Policy.Identity,
        "Accounts": PolicyProtectedAccounts,
        "Action": Policy[ActionKey]
    }
} if {
    Policy := ImpersonationProtectionSetting(Policies, IdentityString, FilterKey)
    count(Policy) > 0

    PolicyProtectedAccounts := { lower(x) | some x in Policy[AccountKey] }
    count(IncludedAccounts - PolicyProtectedAccounts) == 0

    Conditions := [
        (count(IncludedAccounts) > 0) == (count(PolicyProtectedAccounts) > 0),
        (count(IncludedAccounts) == 0) == (count(PolicyProtectedAccounts) == 0)
    ]
    count([x | x := Conditions[_]; x == true]) > 0
} else := {
    "Result": false,
    "Policy": {
        "Name": IdentityString,
        "Accounts": set(),
        "Action": ""
    }
}
