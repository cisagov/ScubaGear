$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'LoadObjectDataIntoPrivilegedUserHashtable' -Force

InModuleScope ExportAADProvider {
    Describe -Tag 'LoadObjectDataIntoPrivilegedUserHashtable' -Name 'Not Found' {
        BeforeAll {
        }

        It 'Deleted user triggers Request_ResourceNotFound exception' {
            # Set up the parameters for the test
            $RoleName = "Global Administrator"  # Mock role
            $PrivilegedUsers = @{}  # Empty hashtable for privileged users
            $ObjectId = [Guid]::NewGuid().Guid  # Random GUID for ObjectId
            $TenantHasPremiumLicense = $true
            $M365Environment = "commercial"

            # Simulate the "Request_ResourceNotFound" exception
            Mock Get-MgBetaDirectoryObject {
                # Write-Host "Inside Get-MgBetaDirectoryObject"
                throw [System.Exception]::new("Request_ResourceNotFound")
            }

            # Track warnings using Assert-MockCalled further down
            Mock Write-Warning

            # Call the function under test
            LoadObjectDataIntoPrivilegedUserHashtable -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment

            # Ensure the Write-Warning was called because Get-MgBetaDirectoryObject throws an exception
            Should -Invoke -CommandName Write-Warning -Times 1

            # Check that the function returned early and did not add anything to $PrivilegedUsers
            $PrivilegedUsers.Count | Should -Be 0
        }

        It 'Objecttype is is a user' {
            # Set up the parameters for the test
            $RoleName = "Global Administrator"  # Mock role
            $PrivilegedUsers = @{}  # Empty hashtable for privileged users
            $ObjectId = [Guid]::NewGuid().Guid  # Random GUID for ObjectId
            $TenantHasPremiumLicense = $true
            $M365Environment = "commercial"

            # Mock Get-MgBetaDirectoryObject to return a user-type object
            Mock Get-MgBetaDirectoryObject {
                [PSCustomObject]@{
                    AdditionalProperties = @{
                        "@odata.type" = "#microsoft.graph.user"  # Simulates a user type
                    }
                }
            }

            # Mock Get-MgBetaUser to return a user with DisplayName and OnPremisesImmutableId
            Mock Get-MgBetaUser {
                [PSCustomObject]@{
                    DisplayName            = "John Doe"
                    OnPremisesImmutableId  = "ABC123"
                }
            }

            # Test 1 - Do NOT pass ObjectType
            LoadObjectDataIntoPrivilegedUserHashtable -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment
            # Assertions to ensure the user was processed correctly
             $PrivilegedUsers[$ObjectId].DisplayName | Should -Be "John Doe"
             $PrivilegedUsers[$ObjectId].OnPremisesImmutableId | Should -Be "ABC123"
             $PrivilegedUsers[$ObjectId].roles | Should -Contain $RoleName

            # Test 2 - Pass ObjectType
            $PrivilegedUsers = @{}
            $Objecttype = "user"
            LoadObjectDataIntoPrivilegedUserHashtable -Objecttype $Objecttype -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense  -M365Environment $M365Environment

            # Assertions to ensure the user was processed correctly
            $PrivilegedUsers[$ObjectId].DisplayName | Should -Be "John Doe"
            $PrivilegedUsers[$ObjectId].OnPremisesImmutableId | Should -Be "ABC123"
            $PrivilegedUsers[$ObjectId].roles | Should -Contain $RoleName
        }


        It 'Objecttype is a group' {
            # Set up the parameters for the test
            $RoleName = "Global Administrator"  # Mock role
            $PrivilegedUsers = @{}  # Empty hashtable for privileged users
            $ObjectId = [Guid]::NewGuid().Guid  # Random GUID for ObjectId, simulating a group ID
            $TenantHasPremiumLicense = $true
            $M365Environment = "commercial"

            # Mock Get-MgBetaDirectoryObject to return a group-type object
            Mock Get-MgBetaDirectoryObject {
                [PSCustomObject]@{
                    AdditionalProperties = @{
                        "@odata.type" = "#microsoft.graph.group"  # Simulates a group type
                    }
                }
            }

            # Mock Get-MgBetaGroupMember to return two group members (users)
            Mock Get-MgBetaGroupMember {
                @(
                    [PSCustomObject]@{
                        Id = [Guid]::NewGuid().Guid
                        AdditionalProperties = @{
                            "@odata.type" = "#microsoft.graph.user"  # First user in the group
                        }
                    },
                    [PSCustomObject]@{
                        Id = [Guid]::NewGuid().Guid
                        AdditionalProperties = @{
                            "@odata.type" = "#microsoft.graph.user"  # Second user in the group
                        }
                    }
                )
            }

            # Mock Get-MgBetaUser to return a user object with DisplayName and OnPremisesImmutableId for both users
            Mock Get-MgBetaUser {
                param ($UserId)
                [PSCustomObject]@{
                    DisplayName            = "User $UserId"
                    OnPremisesImmutableId  = "ImmutableId-$UserId"
                }
            }

            # Mock Invoke-GraphDirectly to return no PIM eligible members
            Mock Invoke-GraphDirectly {
                @()  # Returns an empty array
            }

            ########## Test 1 - Do NOT pass ObjectType
            LoadObjectDataIntoPrivilegedUserHashtable -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment

            # Assertions to ensure the group members were processed correctly
            $PrivilegedUsers.Count | Should -Be 2  # Two users should have been added

            # Ensure both users have their properties set correctly
            $PrivilegedUsers.Values | ForEach-Object {
                $_.roles | Should -Contain $RoleName
                $_.DisplayName | Should -Match "User"
                $_.OnPremisesImmutableId | Should -Match "ImmutableId"
            }

            ########## Test 2 - Pass ObjectType
            $PrivilegedUsers = @{}
            $Objecttype = "group"
            LoadObjectDataIntoPrivilegedUserHashtable -Objecttype $Objecttype -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment

            # Assertions to ensure the group members were processed correctly
            $PrivilegedUsers.Count | Should -Be 2  # Two users should have been added

            # Ensure both users have their properties set correctly
            $PrivilegedUsers.Values | ForEach-Object {
                $_.roles | Should -Contain $RoleName
                $_.DisplayName | Should -Match "User"
                $_.OnPremisesImmutableId | Should -Match "ImmutableId"
            }

            ########## Test 3 - Trigger recursion by mocking Invoke-GraphDirectly to return some users
            $PrivilegedUsers = @{}
            $Objecttype = "group"
             # Mock Invoke-GraphDirectly to return two PIM eligible users (simulating a recursion case)
             Mock Invoke-GraphDirectly {
                @(
                    [PSCustomObject]@{
                        PrincipalId = [Guid]::NewGuid().Guid  # First PIM eligible user
                        AccessId    = "member"  # Simulates eligible PIM member
                    },
                    [PSCustomObject]@{
                        PrincipalId = [Guid]::NewGuid().Guid  # Second PIM eligible user
                        AccessId    = "member"  # Simulates eligible PIM member
                    }
                )
            }

            LoadObjectDataIntoPrivilegedUserHashtable -Objecttype $Objecttype -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment

            # Two group members that each trigger the recursion 2 levels deep = 2 + 2 + 2 = 6
            $PrivilegedUsers.Count | Should -Be 6

            # Ensure all users have their properties set correctly
            $PrivilegedUsers.Values | ForEach-Object {
                $_.roles | Should -Contain $RoleName
                $_.DisplayName | Should -Match "User"
                $_.OnPremisesImmutableId | Should -Match "ImmutableId"
            }
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}