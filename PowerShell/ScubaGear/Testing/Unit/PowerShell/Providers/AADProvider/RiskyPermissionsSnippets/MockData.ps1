$MockApplications = @(
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000001"
        AppId = "10000000-0000-0000-0000-000000000000"
        DisplayName = "Test App 1"
        RequiredResourceAccess = @(
            [PSCustomObject]@{
                ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
                ResourceAccess = @(
                    [PSCustomObject]@{
                        Id = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" # Application.ReadWrite.All
                        Type = "Role"
                    }
                    [PSCustomObject]@{
                        Id = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8" # RoleManagement.ReadWrite.Directory
                        Type = "Role"
                    }
                )
            }
        )
        SignInAudience = "AzureADMultipleOrgs"
        KeyCredentials =  @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000001"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $true
            }
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000002"
                DisplayName = "Test key credential 2"
                StartDateTime = "\/Date(1729876772000)\/" # invalid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $true
            }
        )
        PasswordCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000001"
                DisplayName = "Test password credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $true
            }
        )
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000002"
        AppId = "20000000-0000-0000-0000-000000000000"
        DisplayName = "Test App 2"
        RequiredResourceAccess = @(
            [PSCustomObject]@{
                ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
                ResourceAccess = @(
                    [PSCustomObject]@{
                        Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
                        Type = "Role"
                    }
                )
            }
            [PSCustomObject]@{
                ResourceAppId = "00000002-0000-0ff1-ce00-000000000000" # Office 365 Exchange Online
                ResourceAccess = @(
                    [PSCustomObject]@{
                        Id = "dc890d15-9560-4a4c-9b7f-a736ec74ec40" # full_access_as_app
                        Type = "Role"
                    }
                    [PSCustomObject]@{
                        Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
                        Type = "Role"
                    }
                )
            }
        )
        SignInAudience = "AzureADMyOrg"
        KeyCredentials =  @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000001"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $true
            }
        )
        PasswordCredentials = $null
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000003"
        AppId = "30000000-0000-0000-0000-000000000000"
        DisplayName = "Test App 3"
        RequiredResourceAccess = @(
            [PSCustomObject]@{
                ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
                ResourceAccess = @(
                    [PSCustomObject]@{
                        Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
                        Type = "Role"
                    }
                    [PSCustomObject]@{
                        Id = "01c0a623-fc9b-48e9-b794-0756f8e8f067" # Policy.ReadWrite.ConditionalAccess
                        Type = "Role"
                    }
                    [PSCustomObject]@{
                        Id = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" # Application.ReadWrite.All
                        Type = "Role"
                    }
                )
            }
            [PSCustomObject]@{
                ResourceAppId = "c5393580-f805-4401-95e8-94b7a6ef2fc2" # Office 365 Management APIs
                ResourceAccess = @(
                    [PSCustomObject]@{
                        Id = "4807a72c-ad38-4250-94c9-4eabfe26cd55" # ActivityFeed.ReadDlp
                        Type = "Role"
                    }
                )
            }
        )
        SignInAudience = "AzureADMyOrg"
        KeyCredentials =  $null
        PasswordCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000001"
                DisplayName = "Test password credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $true
            }
        )
    }
)

$MockFederatedCredentials = @(
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000001"
        Name = "federated credential 1"
        Description = ""
        Issuer = "https://token.issuer.domain.com"
        Subject = "repo:testorg/123:refs/tags/1.0"
        Audiences = "api://AzureADTokenExchange"
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000002"
        Name = "federated credential 2"
        Description = ""
        Issuer = "https://token.issuer.domain.com"
        Subject = "repo:testorg/123:refs/tags/1.0"
        Audiences = "api://AzureADTokenExchange"
    }
)

$MockServicePrincipals = @(
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000010"
        AppId = "10000000-0000-0000-0000-000000000000"
        DisplayName = "Test SP 1"
        KeyCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000010"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
        )
        PasswordCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000010"
                DisplayName = "Test password credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
        )
        FederatedIdentityCredentials = $null
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000020"
        AppId = "20000000-0000-0000-0000-000000000000"
        DisplayName = "Test SP 2"
        KeyCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000010"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
        )
        PasswordCredentials = $null
        FederatedIdentityCredentials = $null
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000030"
        AppId = "40000000-0000-0000-0000-000000000000"
        DisplayName = "Test SP 3"
        KeyCredentials = $null
        PasswordCredentials = $null
        FederatedIdentityCredentials = $null
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000040"
        AppId = "50000000-0000-0000-0000-000000000000"
        DisplayName = "Test SP 4"
        KeyCredentials = $null
        PasswordCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000010"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000020"
                DisplayName = "Test key credential 2"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
        )
        FederatedIdentityCredentials = $null
    }
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000050"
        AppId = "60000000-0000-0000-0000-000000000000"
        DisplayName = "Test SP 5"
        KeyCredentials = @(
            [PSCustomObject]@{
                KeyId = "00000000-0000-0000-0000-000000000010"
                DisplayName = "Test key credential 1"
                StartDateTime = "\/Date(1733343742000)\/" # valid credential
                EndDateTime = "\/Date(4102444800000)\/"
                IsFromApplication = $false
            }
        )
        PasswordCredentials = $null
        FederatedIdentityCredentials = $null
    }
)

$MockServicePrincipalAppRoleAssignments = @(
    [PSCustomObject]@{
        AppRoleId = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" # Application.ReadWrite.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8" # RoleManagement.ReadWrite.Directory
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "dbaae8cf-10b5-4b86-a4a1-f871c94c6695" # GroupMember.ReadWrite.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "75359482-378d-4052-8f01-80520e7db3cd" # Files.ReadWrite.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "dc890d15-9560-4a4c-9b7f-a736ec74ec40" # full_access_as_app
        ResourceDisplayName = "Office 365 Exchange Online"
    }
    [PSCustomObject]@{
        AppRoleId = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
        ResourceDisplayName = "Office 365 Exchange Online"
    }
)

$SafePermissions = @(
    [PSCustomObject]@{
        AppRoleId = "2f3e6f8c-093b-4c57-a58b-ba5ce494a169" # Agreement.Read.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "e12dae10-5a57-4817-b79d-dfbec5348930" # AppCatalog.Read.All
        ResourceDisplayName = "Microsoft Graph"
    }
    [PSCustomObject]@{
        AppRoleId = "be95e614-8ef3-49eb-8464-1c9503433b86" # Bookmark.Read.All
        ResourceDisplayName = "Microsoft Graph"
    }
)

$MockApplicationPermissions = @(
    [PSCustomObject]@{
        ResourceDisplayName = "Microsoft Graph"
        RoleId = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" # Application.ReadWrite.All
    }
    [PSCustomObject]@{
        ResourceDisplayName = "Office 365 Management APIs"
        RoleId = "4807a72c-ad38-4250-94c9-4eabfe26cd55" # ActivityFeed.ReadDlp
    }
    [PSCustomObject]@{
        ResourceDisplayName = "Office 365 Exchange Online"
        RoleId = "e2a3a72e-5f79-4c64-b1b1-878b674786c9" # Mail.ReadWrite
    }
)