BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Connection/ConnectHelpers.psm1') -Function Write-ScubaAccessTokenPayload

    function New-TestAccessToken {
        param ([string]$Json, [switch]$KeepPadding)
        $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Json)).Replace('+', '-').Replace('/', '_')
        if (-not $KeepPadding) { $Encoded = $Encoded.TrimEnd('=') }
        "eyJhbGciOiJSUzI1NiJ9.$Encoded.dGVzdA"
    }
}

Describe 'Write-ScubaAccessTokenPayload' {
    It 'prints friendly claims as JSON without returning data or printing the encoded token' {
        $Token = New-TestAccessToken -Json '{"aud":"test-api","iss":"test-issuer","tid":"test-tenant","oid":"test-object","appid":"test-app","scp":"User.Read  Organization.Read.All","roles":["Role.One","Role.Two"],"custom":{"nested":[1,2]}}'

        $Result = @(Write-ScubaAccessTokenPayload -AccessToken $Token -Label '[aad] Microsoft Graph' -InformationVariable TokenInformation)

        $Result.Count | Should -Be 0
        $TokenInformation.Count | Should -Be 1
        $TokenInformation[0].MessageData | Should -Match '^\[aad\] Microsoft Graph decoded access token payload:'
        $TokenInformation[0].MessageData | Should -Not -Match ([regex]::Escape($Token))
        $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
        $Claims.'Audience (aud)' | Should -Be 'test-api'
        $Claims.'Issuer (iss)' | Should -Be 'test-issuer'
        $Claims.'Tenant ID (tid)' | Should -Be 'test-tenant'
        $Claims.'Object ID (oid)' | Should -Be 'test-object'
        $Claims.'Application ID (appid)' | Should -Be 'test-app'
        $Claims.'Delegated permissions (scp)' | Should -Be @('User.Read', 'Organization.Read.All')
        $Claims.'Application roles (roles)' | Should -Be @('Role.One', 'Role.Two')
        $Claims.custom.nested | Should -Be @(1, 2)
    }

    It 'renders issue, activation, and expiration times in UTC while keeping Unix values' {
        $Token = New-TestAccessToken -Json '{"iat":1700000000,"nbf":1700000060,"exp":1700003600}'

        Write-ScubaAccessTokenPayload -AccessToken $Token -InformationVariable TokenInformation

        $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
        $Claims.'Issued at (iat)' | Should -Be '2023-11-14 22:13:20 UTC (1700000000)'
        $Claims.'Not valid before (nbf)' | Should -Be '2023-11-14 22:14:20 UTC (1700000060)'
        $Claims.'Expires at (exp)' | Should -Be '2023-11-14 23:13:20 UTC (1700003600)'
    }

    It 'decodes UTF-8 and base64url characters with <Padding> padding' -TestCases @(
        @{ Padding = 'retained'; KeepPadding = $true }
        @{ Padding = 'removed'; KeepPadding = $false }
    ) {
        param ($KeepPadding)
        # These code points produce both '+' and '/' in base64 at this byte alignment.
        $Text = [string][char]0x083e + [char]0x083f
        $Token = New-TestAccessToken -Json ('{"name":"' + $Text + '","scp":"User.Read"}') -KeepPadding:$KeepPadding

        Write-ScubaAccessTokenPayload -AccessToken $Token -InformationVariable TokenInformation

        $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
        $Claims.'Name (name)' | Should -BeExactly $Text
        ($Claims.'Delegated permissions (scp)' -is [array]) | Should -BeTrue
        $Claims.'Delegated permissions (scp)' | Should -Be @('User.Read')
    }

    It 'restores omitted base64 padding for a payload containing "<Value>"' -TestCases @(
        @{ Value = '' }
        @{ Value = 'a' }
        @{ Value = 'ab' }
    ) {
        param ($Value)
        $Token = New-TestAccessToken -Json ('{"value":"' + $Value + '"}')

        Write-ScubaAccessTokenPayload -AccessToken $Token -InformationVariable TokenInformation

        $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
        $Claims.value | Should -BeExactly $Value
    }

    It 'preserves timestamps that cannot be converted to UTC' {
        $Token = New-TestAccessToken -Json '{"iat":"unknown","exp":9223372036854775807}'

        Write-ScubaAccessTokenPayload -AccessToken $Token -InformationVariable TokenInformation

        $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
        $Claims.'Issued at (iat)' | Should -Be 'unknown'
        $Claims.'Expires at (exp)' | Should -Be 9223372036854775807
    }

    It 'handles <Scenario> without throwing, returning data, or disclosing the token' -TestCases @(
        @{ Scenario = 'an opaque token'; Token = 'opaque-test-access-token' }
        @{ Scenario = 'an encrypted token'; Token = 'header.key.iv.ciphertext.tag' }
        @{ Scenario = 'invalid base64'; Token = 'header.!.signature' }
        @{ Scenario = 'an invalid base64 length'; Token = 'header.a.signature' }
        @{ Scenario = 'invalid JSON'; Token = 'header.bm90LWpzb24.signature' }
        @{ Scenario = 'a JSON array'; Token = 'header.W10.signature' }
        @{ Scenario = 'a JSON scalar'; Token = 'header.MQ.signature' }
        @{ Scenario = 'a JSON null'; Token = 'header.bnVsbA.signature' }
        @{ Scenario = 'an empty token'; Token = '' }
        @{ Scenario = 'a null token'; Token = $null }
    ) {
        param ($Token)

        $Result = @(Write-ScubaAccessTokenPayload -AccessToken $Token -InformationVariable TokenInformation -ErrorAction Stop)

        $Result.Count | Should -Be 0
        $TokenInformation.Count | Should -Be 1
        $TokenInformation[0].MessageData | Should -Match 'could not be decoded'
        if ($Token) {
            $TokenInformation[0].MessageData | Should -Not -Match ([regex]::Escape($Token))
        }
    }
}
