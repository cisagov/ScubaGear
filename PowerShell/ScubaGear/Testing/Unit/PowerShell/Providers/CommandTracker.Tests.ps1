$CommandTrackerPath = '../../../../Modules/Providers/ProviderHelpers/CommandTracker.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $CommandTrackerPath) -Function 'Get-CommandTracker' -Force

InModuleScope CommandTracker {
    Describe -Tag 'Providers' -Name 'CommandTracker exception handling' {
        BeforeAll {
            $AggregateFailurePath = Join-Path -Path $TestDrive -ChildPath 'Invoke-AggregateFailure.ps1'
            @'
$InnerException = [System.InvalidOperationException]::new('Provider returned invalid response')
throw [System.AggregateException]::new('One or more errors occurred.', $InnerException)
'@ | Set-Content -LiteralPath $AggregateFailurePath
        }

        It 'Reports the underlying aggregate exception' {
            $Tracker = Get-CommandTracker
            $Output = & { $Tracker.TryCommand($AggregateFailurePath, @{}, $false) } 3>&1
            $Warnings = @($Output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $WarningLines = $Warnings[0].Message -split '\r?\n'

            $Warnings.Count | Should -Be 1
            $WarningLines | Should -Contain 'Provider returned invalid response'
            $Tracker.GetUnSuccessfulCommands() | Should -Contain $AggregateFailurePath
        }
    }
}

AfterAll {
    Remove-Module CommandTracker -ErrorAction SilentlyContinue
}
