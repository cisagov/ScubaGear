# Training Ground ReadMe

## Level Breakdowns

### Level 1

This is the easy level. Recommend starting here if no prior experience with Rego. This level deals with the basic constructs of SCuBA, simple rules, functions, and basic unit tests. The products with this rating is:

- Sharepoint
- Power Platform

### Level 2

This is the intermediate level. Recommend starting here if some experience with Rego. This level deals with more difficult rules, reporting, and types of unit tests. The products with this rating is:

- Teams
- Exchange Online (Exo)

### Level 3

This is the hard level. Recommend after completing the other levels. This level deals more with complicated/convoluted rules and refactoring duplicate code. The products with this rating is:

- Defender
- Azure Active Directory (AAD)

## Sample Json

### Sharepoint

```json
{
    "SPO_tenant" : [
        {
            "SharingCapability": 0,
            "OneDriveSharingCapability": 0,
            "SharingDomainRestrictionMode": 0,
            "RequireAcceptingAccountMatchInvitedAccount": false,
            "DefaultSharingLinkType": 1,
            "DefaultLinkPermission": 1,
            "RequireAnonymousLinksExpireInDays": 30,
            "FileAnonymousLinkType": 1,
            "FolderAnonymousLinkType": 1,
            "EmailAttestationRequired": true,
            "EmailAttestationReAuthDays": 30
        }
    ],
    "SPO_site": [
        "DenyAddAndCustomizePages": 2
    ]
}
```

### PowerPlatform

```json
{
    "environment_creation": [
        {
            "disableEnvironmentCreationByNonAdminUsers": true,
            "disableTrialEnvironmentCreationByNonAdminUsers": true,
            "disablePortalsCreationByNonAdminUsers": true
        }
    ],
    "dlp_policies": [
        {
            "value": [
                {
                    "displayName": "Block Third-Party Connectors",
                    "connectorGroups": [
                        {
                            "classification": "Confidential",
                            "connectors": [
                                {
                                    "id": "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                                }
                            ]
                        },
                        {
                            "classification": "General",
                            "connectors": [
                                {
                                    "id": "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                                }
                            ]
                        }
                    ],
                    "environments": [
                        {
                            "name": "Default-Test Id"
                        }
                    ]
                }
            ]
        }
    ],
    "environment_list": [
        {
            "EnvironmentName": "Default-Test Id"
        }
    ],
    "tenant_isolation": [
        {
            "properties": {
                "isDisabled": false
            }
        }
    ],
    "tenant_id": "Default-Test Id"
}
```

### Teams

```json
{
    "TODO": true
}
```

### EXO

```json
{
    "TODO": true
}
```

### Defender

```json
{
    "TODO": true
}
```

### AAD

```json
{
    "TODO": true
}
```
