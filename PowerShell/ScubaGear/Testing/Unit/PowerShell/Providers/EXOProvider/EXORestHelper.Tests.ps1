Describe -Tag 'EXORestHelper' -Name 'Invoke-EXORestMethod' {
    BeforeAll {
        # Load Utility first so EXORestHelper reuses this instance and Pester can mock its transport.
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../../Modules/Utility/Utility.psm1') -Force
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force
    }

    It 'Retries a transient connection failure through Invoke-ScubaRestMethod' {
        Mock -ModuleName Utility Start-Sleep {}
        Mock -ModuleName Utility Invoke-RestMethod {
            if ($script:RequestAttempts++ -eq 0) {
                throw 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.'
            }

            [pscustomobject]@{
                value = @([pscustomobject]@{ Identity = 'Default' })
            }
        }
        $script:RequestAttempts = 0

        $Result = Invoke-EXORestMethod -CmdletName 'Get-MalwareFilterPolicy' -ApiEndpoint 'https://example.test/InvokeCommand' -AccessToken 'token' -WarningAction SilentlyContinue

        $Result.Identity | Should -Be 'Default'
        Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 2 -Exactly
        Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly
    }
}

AfterAll {
    Remove-Module EXORestHelper -Force -ErrorAction SilentlyContinue
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
