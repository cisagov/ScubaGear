package eop.utils
import future.keywords

##########################################
# User/Group Exclusion support functions #
##########################################

# Gets Sensitive Users from defender-config.yaml & User rules from ProvidorSettingsExport.json
SensitiveUsers(Policies, PolicyID) := {
    "ConfigUsers" : ConfigUsers,
    "IncludedUsers" : IncludedUsers,
    "ExcludedUsers" : ExcludedUsers
} {
    ConfigUsers := { x | some x in input.scuba_config.Defender[PolicyID].SensitiveAccounts.Users; x != null }
    Policy := [ Policy | Policy := Policies[_]; Policy.Identity == "Strict Preset Security Policy" ]
    IncludedUsers := { x | x := Policy[0].SentTo[_] }
    ExcludedUsers := { x | x := Policy[0].ExceptIfSentTo[_] }
}

# Gets Sensitive Groups from defender-config.yaml & Group rules from ProvidorSettingsExport.json
SensitiveGroups(Policies, PolicyID) := {
    "ConfigGroups" : ConfigGroups,
    "IncludedGroups" : IncludedGroups,
    "ExcludedGroups" : ExcludedGroups
} {
    ConfigGroups := { x | some x in input.scuba_config.Defender[PolicyID].SensitiveAccounts.Groups; x != null }
    Policy := [ Policy | Policy := Policies[_]; Policy.Identity == "Strict Preset Security Policy" ]
    IncludedGroups := { x | x := Policy[0].SentToMemberOf[_] }
    ExcludedGroups := { x | x := Policy[0].ExceptIfSentToMemberOf[_] }
}

# Gets Sensitive Domains from defender-config.yaml & Domain rules from ProvidorSettingsExport.json
SensitiveDomains(Policies, PolicyID) := {
    "ConfigDomains" : ConfigDomains,
    "IncludedDomains" : IncludedDomains,
    "ExcludedDomains" : ExcludedDomains
} {
    ConfigDomains := { x | some x in input.scuba_config.Defender[PolicyID].SensitiveAccounts.Domains; x != null }
    Policy := [ Policy | Policy := Policies[_]; Policy.Identity == "Strict Preset Security Policy" ]
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
# Default case, all users are protected
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null;
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null;
        Policy.RecipientDomainIs == null;
        Policy.ExceptIfRecipientDomainIs == null ]) == 1
}

# No Group requirements
# No Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null;
        Policy.RecipientDomainIs == null;
        Policy.ExceptIfRecipientDomainIs == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) == 0
    count(AllSensitiveUsers.ConfigUsers - AllSensitiveUsers.IncludedUsers) == 0
}

# All User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.RecipientDomainIs == null;
        Policy.ExceptIfRecipientDomainIs == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) == 0
    count(AllSensitiveUsers.ConfigUsers - AllSensitiveUsers.IncludedUsers) == 0

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.IncludedUsers) == true
}

# No Group requirements
# All User accounts indicated in config meet Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo != null;
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) == 0
    count(AllSensitiveUsers.ConfigUsers - AllSensitiveUsers.IncludedUsers) == 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.IncludedUsers) == true
}

# All User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# All User accounts indicated in config meet Domain requirement
# All User accounts indicated in config are not in Excluded
# All User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy" ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) == 0
    count(AllSensitiveUsers.ConfigUsers - AllSensitiveUsers.IncludedUsers) == 0

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.IncludedUsers) == true

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.IncludedUsers) == true
}

# No Excluded User accounts indicated in config meet Group requirements
# (Does not produce true result currently because of code limitations)
# All Included User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.RecipientDomainIs == null;
        Policy.ExceptIfRecipientDomainIs == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) != 0

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.IncludedUsers) == true
    UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.ExcludedUsers) == false
}

# No Group requirements
# No Excluded User accounts indicated in config meet Domain requirement
# All Included User accounts indicated in config meet Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) != 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.IncludedUsers) == true
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.ExcludedUsers) == false
}

# No Excluded User accounts indicated in config meet Group requirements
# (Does not produce true result currently because of code limitations)
# All Included User accounts indicated in config meet Group requirements (Fails currently because of code limitations)
# No Excluded User accounts indicated in config meet Domain requirement
# All Included User accounts indicated in config meet Domain requirement
# Some User accounts indicated in config are in Excluded
# Some User accounts indicated in config are in Included
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy" ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) != 0

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.IncludedUsers) == true
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.IncludedUsers) == true
    Conditions := [
        UsersInGroups(AllSensitiveGroups.IncludedGroups, AllSensitiveUsers.ExcludedUsers) == false,
        UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.ExcludedUsers) == false
    ]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

# All Groups indicated in config are not in Excluded
# All Groups indicated in config are in Included
# No Domain requirement
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null;
        Policy.RecipientDomainIs == null;
        Policy.ExceptIfRecipientDomainIs == null ]) == 1

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    count(AllSensitiveGroups.ConfigGroups & AllSensitiveGroups.ExcludedGroups) == 0
    count(AllSensitiveGroups.ConfigGroups - AllSensitiveGroups.IncludedGroups) == 0
}

# All Groups indicated in config are not in Excluded
# All Groups indicated in config are in Included
# All Groups indicated in config meet Domain requirement
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null ]) == 1

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    count(AllSensitiveGroups.ConfigGroups & AllSensitiveGroups.ExcludedGroups) == 0
    count(AllSensitiveGroups.ConfigGroups - AllSensitiveGroups.IncludedGroups) == 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    GroupsInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveGroups.IncludedGroups) == true
}

# Some Groups indicated in config are in Excluded
# Some Groups indicated in config are in Included
# No Excluded Groups indicated in config meet Domain requirement
# All Included Groups indicated in config meet Domain requirement
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null ]) == 1

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    count(AllSensitiveGroups.ConfigGroups & AllSensitiveGroups.ExcludedGroups) != 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    GroupsInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveGroups.IncludedGroups) == true
    GroupsInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveGroups.ExcludedGroups) == false
}

# No Group requirements
# Groups indicated in config
# All Groups in Domain
# All Domains indicated in config are not in Excluded
# All Domains indicated in config are in Included
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null;
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    count(AllSensitiveGroups.ConfigGroups) > 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    GroupsInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveGroups.IncludedGroups) == true
    count(AllSensitiveDomains.ConfigDomains & AllSensitiveDomains.ExcludedDomains) == 0
    count(AllSensitiveDomains.ConfigDomains - AllSensitiveDomains.IncludedDomains) == 0
}

# No Group requirements
# No Group indicated in config
# All Domains indicated in config are not in Excluded
# All Domains indicated in config are in Included
# No User accounts requirements
# No User accounts indicated in config
SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null;
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveGroups := SensitiveGroups(Policies, PolicyID)
    count(AllSensitiveGroups.ConfigGroups) == 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    count(AllSensitiveDomains.ConfigDomains & AllSensitiveDomains.ExcludedDomains) == 0
    count(AllSensitiveDomains.ConfigDomains - AllSensitiveDomains.IncludedDomains) == 0
}