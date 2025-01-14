$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

using module "$($ModulesPath)/ScubaConfig/ScubaConfig.psm1"

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-RiskyPermission" {
        BeforeAll {
            # Import mock data
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockApplicationPermissions')]
            $MockApplicationPermissions = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplicationPermissions.json") | ConvertFrom-Json

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockServicePrincipalAppRoleAssignments')]
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json
        }

        It "pulls risky permissions from the specified resource (application variant)" {
            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockApplicationPermissions[0].ResourceDisplayName `
                -Id $MockApplicationPermissions[0].RoleId `
                -IsAdminConsented $false

            $Output.RoleId | Should -Match "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
            $Output.RoleDisplayName | Should -Match "Application.ReadWrite.All"
            $Output.ResourceDisplayName | Should -Match "Microsoft Graph"
            $Output.IsAdminConsented | Should -Be $false

            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockApplicationPermissions[1].ResourceDisplayName `
                -Id $MockApplicationPermissions[1].RoleId `
                -IsAdminConsented $false

            $Output.RoleId | Should -Match "4807a72c-ad38-4250-94c9-4eabfe26cd55"
            $Output.RoleDisplayName | Should -Match "ActivityFeed.ReadDlp"
            $Output.ResourceDisplayName | Should -Match "Office 365 Management APIs"
            $Output.IsAdminConsented | Should -Be $false

            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockApplicationPermissions[2].ResourceDisplayName `
                -Id $MockApplicationPermissions[2].RoleId `
                -IsAdminConsented $false

            $Output.RoleId | Should -Match "e2a3a72e-5f79-4c64-b1b1-878b674786c9"
            $Output.RoleDisplayName | Should -Match "Mail.ReadWrite"
            $Output.ResourceDisplayName | Should -Match "Office 365 Exchange Online"
            $Output.IsAdminConsented | Should -Be $false
        }

        It "pulls risky permissions from the specified resource (service principal variant)" {
            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockServicePrincipalAppRoleAssignments[1].ResourceDisplayName `
                -Id $MockServicePrincipalAppRoleAssignments[1].AppRoleId `
                -IsAdminConsented $true

            $Output.RoleId | Should -Match "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"
            $Output.RoleDisplayName | Should -Match "RoleManagement.ReadWrite.Directory"
            $Output.ResourceDisplayName | Should -Match "Microsoft Graph"
            $Output.IsAdminConsented | Should -Be $true

            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockServicePrincipalAppRoleAssignments[5].ResourceDisplayName `
                -Id $MockServicePrincipalAppRoleAssignments[5].AppRoleId `
                -IsAdminConsented $true

            $Output.RoleId | Should -Match "75359482-378d-4052-8f01-80520e7db3cd"
            $Output.RoleDisplayName | Should -Match "Files.ReadWrite.All"
            $Output.ResourceDisplayName | Should -Match "Microsoft Graph"
            $Output.IsAdminConsented | Should -Be $true

            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockServicePrincipalAppRoleAssignments[6].ResourceDisplayName `
                -Id $MockServicePrincipalAppRoleAssignments[6].AppRoleId `
                -IsAdminConsented $true

            $Output.RoleId | Should -Match "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
            $Output.RoleDisplayName | Should -Match "full_access_as_app"
            $Output.ResourceDisplayName | Should -Match "Office 365 Exchange Online"
            $Output.IsAdminConsented | Should -Be $true
        }

        It "formats the return output correctly" {
            $Output = Format-RiskyPermission `
                -Json $PermissionsJson `
                -AppDisplayName $MockApplicationPermissions[0].ResourceDisplayName `
                -Id $MockApplicationPermissions[0].RoleId `
                -IsAdminConsented $false

            $ExpectedKeys = @("RoleId", "RoleDisplayName", "ResourceDisplayName", "IsAdminConsented")
            $Output.PSObject.Properties.Name | Should -Be $ExpectedKeys
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}