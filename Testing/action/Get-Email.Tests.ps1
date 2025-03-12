# The purpose of this test is to verify that the email address can be extracted from the params.

Describe "Get Email Check" {
    It "Extracts the email from the params" {
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/action/Get-Email.ps1' -Resolve
        . $ScriptPath
        # Setup dummy values
        $FakeSetOfParams = "Alias=TenantAlias,TenantDomain=example.onmicrosoft.com,TenantDisplayName=Example Display Name,AppId=12345678-abcd-9012-efgh-345678901234,ProductName=teams,M365Environment=commercial,Emails=someone@example.com"
        # Attempt to extract email from the dummy values
        $Email = Get-Email -ProductAlias TenantAlias -Params $FakeSetOfParams
        $Email | Should -Be "someone@example.com"
    }
}