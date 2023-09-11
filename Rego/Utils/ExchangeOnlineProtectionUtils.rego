package eop.utils
import future.keywords

##########################################
# User/Group Exclusion support functions #
##########################################

# Gets Sensitive Account Filter configuration in defender-config.yaml
SensitiveAccountsConfig(PolicyID) := {
    "IncludedUsers" : IncludedUsers,
    "ExcludedUsers" : ExcludedUsers,
    "IncludedGroups" : IncludedGroups,
    "ExcludedGroups" : ExcludedGroups,
    "IncludedDomains" : IncludedDomains,
    "ExcludedDomains" : ExcludedDomains
} {
    SensitiveAccounts := input.scuba_config.Defender[PolicyID].SensitiveAccounts
    IncludedUsers := { x | some x in SensitiveAccounts.IncludedUsers; x != null }
    ExcludedUsers := { x | some x in SensitiveAccounts.ExcludedUsers; x != null }
    IncludedGroups := { x | some x in SensitiveAccounts.IncludedGroups; x != null }
    ExcludedGroups := { x | some x in SensitiveAccounts.ExcludedGroups; x != null }
    IncludedDomains := { x | some x in SensitiveAccounts.IncludedDomains; x != null }
    ExcludedDomains := { x | some x in SensitiveAccounts.ExcludedDomains; x != null }
}

# Gets Sensitive Account Filter configuration from ProvidorSettingsExport.json
SensitiveAccountsSetting(Policies) := {
    "IncludedUsers" : IncludedUsers,
    "ExcludedUsers" : ExcludedUsers,
    "IncludedGroups" : IncludedGroups,
    "ExcludedGroups" : ExcludedGroups,
    "IncludedDomains" : IncludedDomains,
    "ExcludedDomains" : ExcludedDomains,
    "Policy" : Policy[0]
} {
    Policy := [ Policy | Policy := Policies[_]; Policy.Identity == "Strict Preset Security Policy" ]
    IncludedUsers := { x | x := Policy[0].SentTo[_] }
    ExcludedUsers := { x | x := Policy[0].ExceptIfSentTo[_] }
    IncludedGroups := { x | x := Policy[0].SentToMemberOf[_] }
    ExcludedGroups := { x | x := Policy[0].ExceptIfSentToMemberOf[_] }
    IncludedDomains := { x | x := Policy[0].RecipientDomainIs[_] }
    ExcludedDomains := { x | x := Policy[0].ExceptIfRecipientDomainIs[_] }
}

# TODO: At this time we cannot check what groups users belong to, fail on default
default UsersInGroups(_, _) := false
UsersInGroups(SensitiveGroups, SensitiveUsers) := true if {
    false
}

# Have to include case because function is returning undefined instead of false, still under investigation as to why
UsersInGroups(SensitiveGroups, SensitiveUsers) := false if {
    true
}

default GroupsInDomain(_, _) := false
GroupsInDomain(SensitiveDomain, SensitiveGroups) := true if {
    false
}

# Have to include case because function is returning undefined instead of false, still under investigation as to why
GroupsInDomain(SensitiveDomain, SensitiveGroups) := false if {
    true
}

# Checks if user is part of domain
default UsersInDomain(_, _) := false
UsersInDomain(SensitiveDomain, SensitiveUsers) := true if {
    count(SensitiveDomain) > 0
    UsersInDomain := {
        Result | User := SensitiveUsers[_];
        SplitString := regex.split(".+@", User);
        Result := SplitString[1] in SensitiveDomain
    }
    count([Condition | Condition = UsersInDomain[_]; Condition == false]) == 0
}

# Have to include case because function is returning undefined instead of false, still under investigation as to why
UsersInDomain(SensitiveDomain, SensitiveUsers) := false if {
    count(SensitiveUsers) > 0
    UsersInDomain := {
        Result | User := SensitiveUsers[_];
        SplitString := regex.split(".+@", User);
        Result := SplitString[1] in SensitiveDomain
    }
    count([Condition | Condition = UsersInDomain[_]; Condition == true]) == 0
}

default SensitiveAccounts(_, _) := false
### Case 1 ###
# Default case, all are protected
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0
}

### Case 2 ###
# Default fail, no policy present
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := false if {
    count(SensitiveAccountsSetting.Policy) == 0
}

### Case 3 ###
# No Group requirements
# No Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0

    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedUsers - SensitiveAccountsSetting.IncludedUsers) == 0
}

### Case 4 ###
# All User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedGroups) != 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0

    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedUsers - SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedGroups) > 0
    count(SensitiveAccountsConfig.IncludedGroups - SensitiveAccountsSetting.IncludedGroups) == 0

    UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.IncludedUsers) == true
}

### Case 5 ###
# No Group requirements
# All User accounts indicated in config meet Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) != 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0

    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedUsers - SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedDomains) > 0
    count(SensitiveAccountsConfig.IncludedDomains - SensitiveAccountsSetting.IncludedDomains) == 0

    UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedUsers) == true
}

### Case 6 ###
# All User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# All User accounts indicated in config meet Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedUsers - SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedGroups) > 0
    count(SensitiveAccountsConfig.IncludedDomains) > 0
    count(SensitiveAccountsConfig.IncludedGroups - SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsConfig.IncludedDomains - SensitiveAccountsSetting.IncludedDomains) == 0

    UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.IncludedUsers) == true
    UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedUsers) == true
}

### Case 7 ###
# No Excluded User accounts indicated in config meet Group requirements
# (Does not produce true result currently because of code limitations)
# All Included User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0

    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) != 0
    count(SensitiveAccountsConfig.IncludedGroups) > 0
    count(SensitiveAccountsConfig.IncludedGroups - SensitiveAccountsSetting.IncludedGroups) == 0

    UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.IncludedUsers) == true
    UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.ExcludedUsers) == false
}

### Case 8 ###
# No Group requirements
# No Excluded User accounts indicated in config meet Domain requirement
# All Included User accounts indicated in config meet Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0

    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) != 0
    count(SensitiveAccountsConfig.IncludedDomains) > 0
    count(SensitiveAccountsConfig.IncludedDomains - SensitiveAccountsSetting.IncludedDomains) == 0

    UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedUsers) == true
    UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.ExcludedUsers) == false
}

### Case 9 ###
# No Excluded User accounts indicated in config meet Group requirements
# (Does not produce true result currently because of code limitations)
# All Included User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Excluded User accounts indicated in config meet Domain requirement
# All Included User accounts indicated in config meet Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) != 0

    UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.IncludedUsers) == true
    UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedUsers) == true
    Conditions := [
        UsersInGroups(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting.ExcludedUsers) == false,
        UsersInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.ExcludedUsers) == false
    ]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

### Case 10 ###
# All Groups indicated in config are not in Excluded
# All Groups indicated in config are in Included
# No Domain requirement
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0

    count(SensitiveAccountsConfig.IncludedUsers) == 0
    count(SensitiveAccountsConfig.ExcludedUsers) == 0

    count(SensitiveAccountsConfig.IncludedGroups & SensitiveAccountsSetting.ExcludedGroups) == 0
    count(SensitiveAccountsConfig.IncludedGroups - SensitiveAccountsSetting.IncludedGroups) == 0
}

### Case 11 ###
# All Groups indicated in config are not in Excluded
# All Groups indicated in config are in Included
# All Groups indicated in config meet Domain requirement
# (Does not produce true result currently because of code limitations)
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0

    count(SensitiveAccountsConfig.IncludedUsers) == 0
    count(SensitiveAccountsConfig.ExcludedUsers) == 0

    count(SensitiveAccountsConfig.IncludedGroups & SensitiveAccountsSetting.ExcludedGroups) == 0
    count(SensitiveAccountsConfig.IncludedGroups - SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsConfig.IncludedGroups) > 0
    GroupsInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedGroups) == true
}

### Case 12 ###
# Some Groups indicated in config are in Excluded
# Some Groups indicated in config are in Included
# No Excluded Groups indicated in config meet Domain requirement
# (Does not produce true result currently because of code limitations)
# All Included Groups indicated in config meet Domain requirement
# (Does not produce true result currently because of code limitations)
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0

    count(SensitiveAccountsConfig.IncludedUsers) == 0
    count(SensitiveAccountsConfig.ExcludedUsers) == 0

    count(SensitiveAccountsConfig.IncludedGroups & SensitiveAccountsSetting.ExcludedGroups) != 0

    GroupsInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.IncludedGroups) == true
    GroupsInDomain(SensitiveAccountsSetting.IncludedDomains, SensitiveAccountsSetting.ExcludedGroups) == false
}

### Case 13 ###
# No Group requirements
# No Group indicated in config
# All Domains indicated in config are not in Excluded
# All Domains indicated in config are in Included
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0

    count(SensitiveAccountsConfig.IncludedUsers) == 0
    count(SensitiveAccountsConfig.ExcludedUsers) == 0
    count(SensitiveAccountsConfig.IncludedGroups) == 0
    count(SensitiveAccountsConfig.ExcludedGroups) == 0
    count(SensitiveAccountsConfig.ExcludedDomains & SensitiveAccountsSetting.ExcludedDomains) == 0
    count(SensitiveAccountsConfig.IncludedDomains - SensitiveAccountsSetting.IncludedDomains) == 0
}