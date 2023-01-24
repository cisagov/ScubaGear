BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportAADProvider.psm1
    $GraphScopes = (
        'User.Read.All',
        'Policy.Read.All',
        'Organization.Read.All',
        'UserAuthenticationMethod.Read.All',
        'RoleManagement.Read.Directory',
        'GroupMember.Read.All',
        'Directory.Read.All'
    )
    $GraphParams = @{
        'Scopes' = $GraphScopes;
        'ErrorAction' = 'Stop';
    }
    Connect-MgGraph @GraphParams | Out-Null
}

Describe "Export-AADProvider" {
    It "return JSON" {
        InModuleScope ExportAADProvider {
            $json = Export-AADProvider
            $json = $json.TrimEnd(",")
            $json = "{$($json)}"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}

Describe "Export-AADProvider" {
    It "return JSON" {
        InModuleScope ExportAADProvider {
            $Json = Get-AADTenantDetail
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}
