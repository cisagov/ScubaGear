package sharepoint_test
import rego.v1

SPOTenant := {
    "SharingCapability": 0,
    "ODBSharingCapability": 0,
    "SharingDomainRestrictionMode": 0,
    "DefaultSharingLinkType": 1,
    "DefaultLinkPermission": 1,
    "RequireAnonymousLinksExpireInDays": 30,
    "FileAnonymousLinkType": 1,
    "FolderAnonymousLinkType": 1,
    "EmailAttestationRequired": true,
    "EmailAttestationReAuthDays": 30
}

#############
# Constants #
#############

# Values in json for slider sharepoint/onedrive sharing settings
# ONLYPEOPLEINORG := 0        # "Disabled" in functional tests
# EXISTINGGUESTS := 3         # "ExistingExternalUserSharingOnly" in functional tests
# NEWANDEXISTINGGUESTS := 1   # "ExternalUserSharingOnly" in functional tests
# ANYONE := 2                 # "ExternalUserAndGuestSharing" in functional tests