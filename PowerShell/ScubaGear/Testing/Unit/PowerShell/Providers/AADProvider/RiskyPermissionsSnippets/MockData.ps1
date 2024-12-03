$MockApplications = @(
    [PSCustomObject]@{
        Id = "00000000-0000-0000-0000-000000000001"
        AppId = "00000000-0000-0000-0000-000000000000"
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
        AppId = "00000000-0000-0000-0000-000000000000"
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
        PasswordCredentials = @()
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