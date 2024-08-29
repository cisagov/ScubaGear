$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Out-Utf8NoBom' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Out-Utf8NoBom' {
        BeforeAll {
            function Invoke-WriteAllLines {}
            Mock -ModuleName Orchestrator Invoke-WriteAllLines

            # Setup test directories for testing
            New-Item -ItemType Directory './a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './c' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/c' -Force -ErrorAction Ignore
            # New-SmbShare -Name "Shared" -Path ".\shared" -ReadAccess "Everyone"

            $pwd = Get-Location
        }

        Context 'local file' {
            It 'Write to root drive path' {
                Out-Utf8NoBom -Content "test" -Location "C:\" -FileName "output.json" `
                | Should -Be "C:\output.json"
            }

            It 'Write to local subdirectory path' {
                Out-Utf8NoBom -Content "test" -Location "a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }
        }

        # # Requires ability to create SMB shares on your box to run
        # Context 'UNC path' {
        #     It 'Write to shared UNC path' {
        #                         Out-Utf8NoBom -Content "test" -Location "$env:COMPUTERNAME\Shared" -FileName "output.json" `
        #         | Should -Be "\\$env:COMPUTERNAME\Shared\output.json"
        #     }
        # }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
    Remove-SmbShare -Name Shared -ErrorAction Ignore
    Remove-Item -Path "./c" -Force -ErrorAction Ignore
    Remove-Item -Path "./a" -Recurse -Force -ErrorAction Ignore
    Remove-Item -Path "./shared" -Recurse -Force -ErrorAction Ignore
}
