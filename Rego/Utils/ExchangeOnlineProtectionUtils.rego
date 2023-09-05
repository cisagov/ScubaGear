package eop.utils
import future.keywords

##########################################
# User/Group Exclusion support functions #
##########################################

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

SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveUsers := SensitiveUsers(Policies, PolicyID)
    count(AllSensitiveUsers.ConfigUsers & AllSensitiveUsers.ExcludedUsers) == 0
    count(AllSensitiveUsers.ConfigUsers - AllSensitiveUsers.IncludedUsers) == 0

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    UsersInDomain(AllSensitiveDomains.IncludedDomains, AllSensitiveUsers.IncludedUsers) == true
}

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

SensitiveAccounts(Policies, PolicyID) := true if {
    count([ Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.ExceptIfSentTo == null;
        Policy.SentToMemberOf == null;
        Policy.ExceptIfSentToMemberOf == null ]) == 1

    AllSensitiveDomains := SensitiveDomains(Policies, PolicyID)
    count(AllSensitiveDomains.ConfigDomains & AllSensitiveDomains.ExcludedDomains) == 0
    count(AllSensitiveDomains.ConfigDomains - AllSensitiveDomains.IncludedDomains) == 0
}