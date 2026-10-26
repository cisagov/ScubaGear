Import-Module (Join-Path $PSScriptRoot '../../../../Modules/RunRego')

Describe 'Invoke-ExternalCmd process output handling' {
    InModuleScope RunRego {
        BeforeAll {
            # Pester shares this value with the It blocks at runtime.
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ShellPath')]
            $ShellPath = (Get-Process -Id $PID).Path
        }

        BeforeEach {
            Mock Write-ScubaLog {}
        }

        It 'Reports <Case> on failure' -ForEach @(
            @{ Case = 'stdout only'; Script = '[Console]::Out.Write("stdout diagnostic"); exit 2'; StdOut = $true; StdErr = $false },
            @{ Case = 'stderr only'; Script = '[Console]::Error.Write("stderr diagnostic"); exit 2'; StdOut = $false; StdErr = $true },
            @{ Case = 'both streams'; Script = '[Console]::Out.Write("stdout diagnostic"); [Console]::Error.Write("stderr diagnostic"); exit 2'; StdOut = $true; StdErr = $true },
            @{ Case = 'neither stream'; Script = 'exit 2'; StdOut = $false; StdErr = $false }
        ) {
            $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Script))
            $Failure = $null
            try {
                Invoke-ExternalCmd -LiteralPath $ShellPath -PassThruArgs @('-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded)
            }
            catch {
                $Failure = $_
            }
            $Failure | Should -Not -BeNullOrEmpty
            $Message = $Failure.Exception.Message
            $Message | Should -Match 'exit code 2'
            $Message | Should -Match ([regex]::Escape($ShellPath))
            if ($StdOut) {
                $Message | Should -Match 'Standard output:\s+stdout diagnostic'
            }
            else {
                $Message | Should -Not -Match 'Standard output:'
            }
            if ($StdErr) {
                $Message | Should -Match 'Standard error:\s+stderr diagnostic'
            }
            else {
                $Message | Should -Not -Match 'Standard error:'
            }
            if (-not $StdOut -and -not $StdErr) {
                $Message | Should -Match 'No output was captured from either stream'
            }
        }

        It 'Returns only stdout on success even when stderr is present' {
            $Script = '[Console]::Out.Write("success output"); [Console]::Error.Write("warning"); exit 0'
            $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Script))
            $Result = Invoke-ExternalCmd -LiteralPath $ShellPath -PassThruArgs @('-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded)
            $Result | Should -BeExactly 'success output'
        }

        It 'Identifies a failure to start separately from a nonzero exit' {
            $InvalidExecutable = Join-Path $TestDrive 'invalid.exe'
            Set-Content -LiteralPath $InvalidExecutable -Value 'This is not an executable.'
            { Invoke-ExternalCmd -LiteralPath $InvalidExecutable } | Should -Throw '*Failed to start process*'
        }
    }
}
