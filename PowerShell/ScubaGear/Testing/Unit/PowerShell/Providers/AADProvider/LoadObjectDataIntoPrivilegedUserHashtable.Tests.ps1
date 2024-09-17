$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'LoadObjectDataIntoPrivilegedUserHashtable' -Force

InModuleScope ExportAADProvider {
    Describe -Tag 'LoadObjectDataIntoPrivilegedUserHashtable' -Name 'Not Found' {
        BeforeAll {
        }
        It 'Deleted user Request_ResourceNotFound' {
            # Set up the parameters for the test
            $Role = [PSCustomObject]@{ DisplayName = "Global Administrator" }  # Mock role with DisplayName
            $PrivilegedUsers = @{}  # Empty hashtable for privileged users
            $ObjectId = [Guid]::NewGuid().Guid  # Random GUID for ObjectId
            $TenantHasPremiumLicense = $true

            # Simulate the "Request_ResourceNotFound" exception
            Mock Get-MgBetaDirectoryObject {
                # Write-Host "Inside Get-MgBetaDirectoryObject"
                throw [System.Exception]::new("Request_ResourceNotFound")
            }

            # Track warnings using Assert-MockCalled further down
            Mock Write-Warning

            # Call the function under test
            LoadObjectDataIntoPrivilegedUserHashtable -Role $Role -PrivilegedUsers $PrivilegedUsers -ObjectId $ObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense

            # Ensure the Write-Warning was called because Get-MgBetaDirectoryObject throws an exception
            Should -Invoke -CommandName Write-Warning -Times 1

            # Check that the function returned early and did not add anything to $PrivilegedUsers
            $PrivilegedUsers.Count | Should -Be 0
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}