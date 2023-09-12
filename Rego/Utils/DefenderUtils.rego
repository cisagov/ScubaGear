package defender.utils
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
} else := {
    "IncludedUsers" : set(),
    "ExcludedUsers" : set(),
    "IncludedGroups" : set(),
    "ExcludedGroups" : set(),
    "IncludedDomains" : set(),
    "ExcludedDomains" : set()
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

default UserInGroups(_, _) := false
UserInGroups(_, SensitiveAccountsSetting) := true {
    count(SensitiveAccountsSetting.IncludedGroups) == 0
}

UserInGroups(_, SensitiveAccountsSetting) := false {
    count(SensitiveAccountsSetting.IncludedGroups) > 0
}

default GroupsInDomain(_, _) := false
GroupsInDomain(_, SensitiveAccountsSetting) := true {
    count(SensitiveAccountsSetting.IncludedDomains) == 0
}

GroupsInDomain(_, SensitiveAccountsSetting) := false {
    count(SensitiveAccountsSetting.IncludedDomains) > 0
}

default UserInDomain(_, _) := false
UserInDomain(_, SensitiveAccountsSetting) := true {
    count(SensitiveAccountsSetting.IncludedDomains) == 0
}

UserInDomain(UserToCheck, SensitiveAccountsSetting) := true {
    count(SensitiveAccountsSetting.IncludedDomains) > 0
    UsersInDomain := {
        Result | User := UserToCheck[_];
        SplitString := regex.split(".+@", User);
        Result := SplitString[1] in SensitiveAccountsSetting.IncludedDomains
    }
    count([Condition | Condition = UsersInDomain[_]; Condition == false]) == 0
}

UserInDomain(UserToCheck, SensitiveAccountsSetting) := false {
    count(SensitiveAccountsSetting.IncludedDomains) > 0
    UsersInDomain := {
        Result | User := UserToCheck[_];
        SplitString := regex.split(".+@", User);
        Result := SplitString[1] in SensitiveAccountsSetting.IncludedDomains
    }
    count([Condition | Condition = UsersInDomain[_]; Condition == true]) == 0
}

default CheckUserWithoutExcluded(_, _) := false
CheckUserWithoutExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) := true {
    SensitiveAccountsConfig.IncludedUsers == SensitiveAccountsSetting.IncludedUsers
    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) == 0
    SensitiveAccountsConfig.IncludedGroups == SensitiveAccountsSetting.IncludedGroups
    SensitiveAccountsConfig.IncludedDomains == SensitiveAccountsSetting.IncludedDomains
    UserInGroups(SensitiveAccountsSetting.IncludedUsers, SensitiveAccountsSetting) == true
    UserInDomain(SensitiveAccountsSetting.IncludedUsers, SensitiveAccountsSetting) == true
} else := false

default CheckUserWithExcluded(_, _) := false
CheckUserWithExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) := true {
    count(SensitiveAccountsConfig.IncludedUsers & SensitiveAccountsSetting.ExcludedUsers) > 0
    SensitiveAccountsConfig.IncludedGroups == SensitiveAccountsSetting.IncludedGroups
    SensitiveAccountsConfig.IncludedDomains == SensitiveAccountsSetting.IncludedDomains

    GroupCondition := [
        count(SensitiveAccountsSetting.IncludedGroups) > 0,
        # This fails on default giving a false positive, once comparison is actually available, should change to == false
        UserInGroups(SensitiveAccountsSetting.ExcludedUsers, SensitiveAccountsSetting) == true
    ]
    print(GroupCondition)
    DomainConditions := [
        count(SensitiveAccountsSetting.IncludedDomains) > 0,
        UserInDomain(SensitiveAccountsSetting.ExcludedUsers, SensitiveAccountsSetting) == false
    ]
    print(DomainConditions)
    Conditions := [
        count([Condition | Condition = GroupCondition[_]; Condition == true]) == 2,
        count([Condition | Condition = DomainConditions[_]; Condition == true]) == 2
    ]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
} else := false

default CheckGroupWithoutExcluded(_, _) := false
CheckGroupWithoutExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) := true {
	count(SensitiveAccountsConfig.IncludedGroups & SensitiveAccountsSetting.ExcludedGroups) == 0
    SensitiveAccountsConfig.IncludedGroups == SensitiveAccountsSetting.IncludedGroups
    SensitiveAccountsConfig.IncludedDomains == SensitiveAccountsSetting.IncludedDomains
    GroupsInDomain(SensitiveAccountsSetting.IncludedGroups, SensitiveAccountsSetting) == true
} else := false

default CheckGroupWithExcluded(_, _) := false
CheckGroupWithExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) := false {
    count(SensitiveAccountsConfig.IncludedGroups & SensitiveAccountsSetting.ExcludedGroups) > 0
    SensitiveAccountsConfig.IncludedDomains == SensitiveAccountsSetting.IncludedDomains
} else := false

default SensitiveAccounts(_, _) := false
# Default case, all are protected
SensitiveAccounts(SensitiveAccountsSetting, _) := true if {
    count(SensitiveAccountsSetting.Policy) > 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0
    count(SensitiveAccountsSetting.IncludedDomains) == 0
    count(SensitiveAccountsSetting.ExcludedDomains) == 0
}

# All specified users are protected
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) > 0

    UserConditions := [
        count(SensitiveAccountsSetting.IncludedUsers) != 0,
        count(SensitiveAccountsSetting.ExcludedUsers) != 0
    ]
    count([Condition | Condition = UserConditions[_]; Condition == true]) > 0

    ExcludedConditions := [
        CheckUserWithoutExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) == true,
        CheckUserWithExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) == true
    ]
    count([Condition | Condition = ExcludedConditions[_]; Condition == true]) > 0
}

# All specified group members are protected
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) > 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    ExcludedConditions := [
        CheckGroupWithoutExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) == true,
        CheckGroupWithExcluded(SensitiveAccountsSetting, SensitiveAccountsConfig) == true
    ]
    count([Condition | Condition = ExcludedConditions[_]; Condition == true]) > 0
}

# All specified domains are protected
SensitiveAccounts(SensitiveAccountsSetting, SensitiveAccountsConfig) := true if {
    count(SensitiveAccountsSetting.Policy) >= 0
    count(SensitiveAccountsSetting.IncludedUsers) == 0
    count(SensitiveAccountsSetting.ExcludedUsers) == 0
    count(SensitiveAccountsSetting.IncludedGroups) == 0
    count(SensitiveAccountsSetting.ExcludedGroups) == 0

    SensitiveAccountsSetting.IncludedDomains == SensitiveAccountsConfig.IncludedDomains
    count(SensitiveAccountsConfig.IncludedDomains & SensitiveAccountsSetting.ExcludedDomains) == 0
}