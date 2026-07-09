$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-RiskyAppPermissionsJson" {
        BeforeEach {
            $script:CachedRiskyAppPermissionsJson = $null
            $script:CachedPermissionLookup = $null
        }

        It "loads and caches parsed JSON" {
            $MockRiskyJson = @'
{
  "resources": {
    "00000003-0000-0000-c000-000000000000": "Microsoft Graph"
  },
  "permissions": {
    "Microsoft Graph": {
      "Application": {
        "11111111-1111-1111-1111-111111111111": {
          "Name": "Application.ReadWrite.All",
          "RiskLevel": "Critical"
        }
      }
    }
  }
}
'@

            Mock Get-Content {
                return $MockRiskyJson
            } -ModuleName AADRiskyPermissionsHelper

            $FirstResult = Get-RiskyAppPermissionsJson
            $SecondResult = Get-RiskyAppPermissionsJson

            $FirstResult | Should -Not -BeNullOrEmpty
            $FirstResult.resources.'00000003-0000-0000-c000-000000000000' | Should -Be "Microsoft Graph"
            $script:CachedPermissionLookup | Should -Not -BeNullOrEmpty
            [object]::ReferenceEquals($FirstResult, $SecondResult) | Should -BeTrue
            Assert-MockCalled Get-Content -Times 1 -ModuleName AADRiskyPermissionsHelper
        }

        It "seeds the permission lookup cache on first load" {
            $MockRiskyJson = @'
{
  "resources": {
    "00000003-0000-0000-c000-000000000000": "Microsoft Graph"
  },
  "permissions": {
    "Microsoft Graph": {
      "Delegated": {
        "22222222-2222-2222-2222-222222222222": {
          "Name": "User.Read.All",
          "RiskLevel": "High"
        }
      }
    }
  }
}
'@

            Mock Get-Content {
                return $MockRiskyJson
            } -ModuleName AADRiskyPermissionsHelper

            $null = Get-RiskyAppPermissionsJson

            $script:CachedPermissionLookup.ContainsKey("Microsoft Graph") | Should -BeTrue
            $script:CachedPermissionLookup["Microsoft Graph"].ContainsKey("Delegated") | Should -BeTrue
            $script:CachedPermissionLookup["Microsoft Graph"]["Delegated"].ContainsKey("22222222-2222-2222-2222-222222222222") | Should -BeTrue
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}
