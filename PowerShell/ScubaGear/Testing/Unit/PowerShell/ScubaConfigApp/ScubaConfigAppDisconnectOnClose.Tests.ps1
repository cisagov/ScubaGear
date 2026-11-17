Describe -Tag 'ScubaConfigApp' -Name 'Start-SCuBAConfigApp disconnects from Microsoft Graph when the window closes' {
    BeforeAll {
        $ModulePath = (Resolve-Path "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp.psm1").Path
        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$null, [ref]$null)
        $Function = $Ast.Find({
            param($Node)
            $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $Node.Name -eq 'Start-SCuBAConfigApp'
        }, $true)
        $Text = $Function.Extent.Text

        $ClosingStart = $Text.IndexOf('Window.Add_Closing({')
        $ClosedStart = $Text.IndexOf('Window.Add_Closed({')
        $script:ClosingHandler = $Text.Substring($ClosingStart, $ClosedStart - $ClosingStart)
        $script:AfterWindowEnds = $Text.Substring($Text.IndexOf('EndInvoke($AsyncHandle)'))
        $WaitStart = $Text.IndexOf('$AsyncHandle = $PowerShellCommand.BeginInvoke()')
        $script:WaitForWindow = $Text.Substring($WaitStart, $Text.IndexOf('EndInvoke($AsyncHandle)') - $WaitStart)
    }

    # While this runspace runs script (a Start-Sleep polling loop), scriptblocks bound to it that the window calls, such as
    # ShowMessageBox, are run on this runspace's thread instead of the window's. Reading the window handle then fails and
    # every dialog, including the close confirmation, breaks. A single blocking EndInvoke leaves them on the window's thread.
    It 'waits for the window with one blocking call, not a polling loop' {
        $WaitForWindow | Should -Not -Match 'Start-Sleep'
        $WaitForWindow | Should -Not -Match 'IsCompleted'
    }

    # The close handler runs in the window's own runspace, which does not have ScubaGear's connection commands. Calling one
    # there throws before anything is disconnected, so the sign-in survived the close while the console claimed otherwise.
    It 'does not call connection commands from the window close handler' {
        $ClosingHandler | Should -Not -Match 'Get-ScubaGraphContext'
        $ClosingHandler | Should -Not -Match 'Disconnect-ScubaGraph'
    }

    It 'disconnects after the window has ended' {
        $AfterWindowEnds | Should -Match 'Disconnect-ScubaGraph'
    }

    It 'says it disconnected only after it actually disconnected' {
        $DisconnectAt = $AfterWindowEnds.IndexOf('Disconnect-ScubaGraph')
        $MessageAt = $AfterWindowEnds.IndexOf('Disconnected from Microsoft Graph')
        $DisconnectAt | Should -BeGreaterThan -1
        $MessageAt | Should -BeGreaterThan $DisconnectAt
    }
}
