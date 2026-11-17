[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

# The config app and analyzer run Graph work in their own runspaces. They hand those runspaces the caller's
# ScubaGearState so everything shares one sign-in. These tests run in a child process because importing
# ConnectHelpers into a second runspace inside the Pester process disturbs the other tests.
Describe -Tag 'Connection' -Name 'ScubaGearState shared with another runspace' {
    BeforeAll {
        $ConnectHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection\ConnectHelpers.psm1' -Resolve
        $HostPath = (Get-Process -Id $PID).Path

        $ChildScript = @'
param($ModulePath)
$State = [hashtable]::Synchronized(@{ Session = @{ Marker = 'caller-session' }; MsalAppCache = @{}; MsalValidated = $false; MsalLibraryPath = $null; LastRun = $null })
$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()
$Runspace.SessionStateProxy.SetVariable('ScubaGearState', $State)
$Worker = [powershell]::Create()
$Worker.Runspace = $Runspace
[void]$Worker.AddScript({
    param($ModulePath)
    Import-Module $ModulePath -Function Invoke-ScubaGraphRequest, Disconnect-ScubaGraph -Force
    $Seen = $Global:ScubaGearState.Session.Marker
    Disconnect-ScubaGraph
    $Seen
}).AddArgument($ModulePath)
$SeenInWorker = @($Worker.Invoke())[0]
$Worker.Dispose()
$Runspace.Dispose()
[pscustomobject]@{ SeenInWorker = $SeenInWorker; SessionAfterWorkerDisconnect = $State.Session } | ConvertTo-Json -Compress
'@
        $ScriptFile = Join-Path -Path $TestDrive -ChildPath 'SharedRunspace.ps1'
        Set-Content -Path $ScriptFile -Value $ChildScript

        $Output = & $HostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptFile -ModulePath $ConnectHelpersPath
        $script:Result = ($Output | Where-Object { $_ -like '{*' } | Select-Object -Last 1) | ConvertFrom-Json
    }

    It 'Lets the other runspace see the session the caller signed in with' {
        $script:Result.SeenInWorker | Should -Be 'caller-session'
    }

    It 'Clears the caller''s session when the other runspace disconnects' {
        $script:Result.SessionAfterWorkerDisconnect | Should -BeNullOrEmpty
    }
}

Describe -Tag 'Connection' -Name 'ScubaGearState type' {
    It 'Is synchronized so the UI thread and background threads can share it' {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection\ConnectHelpers.psm1') -Function 'Get-ScubaGearContext' -Force
        $Global:ScubaGearState.IsSynchronized | Should -BeTrue
    }
}
