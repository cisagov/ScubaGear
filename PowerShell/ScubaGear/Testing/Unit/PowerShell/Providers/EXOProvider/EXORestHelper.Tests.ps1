$HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force

Describe -Tag 'EXORestHelper' -Name 'Invoke-EXORestMethod' {
    It 'Retries a transient connection failure' {
        Mock -ModuleName EXORestHelper Start-Sleep {}
        Mock -ModuleName EXORestHelper Invoke-WebRequest {
            if ($script:RequestAttempts++ -eq 0) {
                throw 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.'
            }

            [pscustomobject]@{
                Content = '{"value":[{"Identity":"Default"}]}'
            }
        }
        $script:RequestAttempts = 0

        $Result = Invoke-EXORestMethod -CmdletName 'Get-MalwareFilterPolicy' -ApiEndpoint 'https://example.test/InvokeCommand' -AccessToken 'token'

        $Result.Identity | Should -Be 'Default'
        Should -Invoke -ModuleName EXORestHelper Invoke-WebRequest -Times 2 -Exactly
        Should -Invoke -ModuleName EXORestHelper Start-Sleep -Times 1 -Exactly
    }
}

AfterAll {
    Remove-Module EXORestHelper -Force -ErrorAction SilentlyContinue
}