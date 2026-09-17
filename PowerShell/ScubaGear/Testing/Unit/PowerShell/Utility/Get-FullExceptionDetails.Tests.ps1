$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Get-FullExceptionDetails' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Get-FullExceptionDetails' {
        It 'Returns the original details for a non-aggregate exception' {
            try {
                throw [System.InvalidOperationException]::new('Authentication failed')
            }
            catch {
                $Details = Get-FullExceptionDetails -ErrorRecord $_
            }

            $Details.Message | Should -Be 'Authentication failed'
            $Details.StackTrace | Should -Not -BeNullOrEmpty
        }

        It 'Returns every nested aggregate exception message on a separate line' {
            $FirstException = [System.InvalidOperationException]::new('Application does not exist in the tenant')
            $NestedException = [System.Exception]::new(
                'Provider request failed',
                [System.ArgumentException]::new('Provider returned invalid data')
            )
            $AggregateException = [System.AggregateException]::new(
                'One or more errors occurred.',
                [System.Exception[]]@($FirstException, $NestedException)
            )

            try {
                throw $AggregateException
            }
            catch {
                $Details = Get-FullExceptionDetails -ErrorRecord $_
            }

            $MessageLines = $Details.Message -split '\r?\n'
            $MessageLines[0] | Should -Match '^One or more errors occurred\.'
            $MessageLines | Should -Contain 'Application does not exist in the tenant'
            $MessageLines | Should -Contain 'Provider request failed'
            $MessageLines | Should -Contain 'Provider returned invalid data'
            $Details.StackTrace | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module Utility -ErrorAction SilentlyContinue
}
