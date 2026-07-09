Describe "RiskyAppPermissions cloud mappings" {
    BeforeAll {
        $SchemaPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../../../../schemas/RiskyAppPermissions.json"

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RiskyAppPermissions')]
        $RiskyAppPermissions = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'AllowedCloudValues')]
        $AllowedCloudValues = @("Commercial", "GCC", "GCCHigh", "DoD")

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RequiredGcchighGuidMap')]
        $RequiredGcchighGuidMap = @{
            "ecd0c692-8a5a-49fc-9e89-ecbbb58b04a9" = "SharePointTenantSettings.Read.All"
            "70549927-dd38-44e4-a76f-e91b5ec6acc4" = "TeamworkDevice.ReadWrite.All"
            "8cbe86c1-747b-4599-a1bc-f872f7f221f0" = "Presence.Read.All"
            "a76e26a7-ad88-4264-bb86-01a1e214c175" = "SecurityAlert.ReadWrite.All"
        }
    }

    It "keeps Name and RiskLevel populated for all permissions" {
        foreach ($Resource in $RiskyAppPermissions.permissions.PSObject.Properties) {
            foreach ($RoleType in $Resource.Value.PSObject.Properties) {
                if ($RoleType.Name.StartsWith("_")) {
                    continue
                }

                foreach ($Permission in $RoleType.Value.PSObject.Properties) {
                    $Permission.Value.Name | Should -Not -BeNullOrEmpty
                    $Permission.Value.RiskLevel | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    It "uses only allowed values when Clouds metadata is present" {
        foreach ($Resource in $RiskyAppPermissions.permissions.PSObject.Properties) {
            foreach ($RoleType in $Resource.Value.PSObject.Properties) {
                if ($RoleType.Name.StartsWith("_")) {
                    continue
                }

                foreach ($Permission in $RoleType.Value.PSObject.Properties) {
                    if ($Permission.Value.PSObject.Properties.Name -contains "Clouds") {
                        @($Permission.Value.Clouds).Count | Should -BeGreaterThan 0
                        foreach ($Cloud in @($Permission.Value.Clouds)) {
                            $AllowedCloudValues -contains $Cloud | Should -BeTrue
                        }
                    }
                }
            }
        }
    }

    It "contains required GCCHigh GUID mappings" {
        $GraphApplicationPermissions = $RiskyAppPermissions.permissions."Microsoft Graph".Application

        foreach ($Guid in $RequiredGcchighGuidMap.Keys) {
            $GraphApplicationPermissions.PSObject.Properties.Name | Should -Contain $Guid
            $GraphApplicationPermissions.$Guid.Name | Should -Be $RequiredGcchighGuidMap[$Guid]
            @($GraphApplicationPermissions.$Guid.Clouds) | Should -Contain "GCCHigh"
        }
    }
}
