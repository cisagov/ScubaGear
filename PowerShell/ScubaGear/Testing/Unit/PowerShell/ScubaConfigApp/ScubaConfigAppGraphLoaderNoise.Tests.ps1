Describe 'Select-ActionableError' {
    BeforeAll {
        $modulePath = (Resolve-Path "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp.psm1").Path
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { throw ($parseErrors -join "`n") }
        $function = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Select-ActionableError'
        }, $true)
        . ([scriptblock]::Create($function.Extent.Text))

        # Load invalid DLL files the same way the Graph 5.1 loader does so the records are real.
        function Get-LoadFailureRecord {
            param([string]$Path)
            $Error.Clear()
            try { $null = [System.Reflection.Assembly]::LoadFrom($Path) } catch { Write-Verbose "expected load failure" }
            $Error[0]
        }
        $script:msalCopy = Join-Path $TestDrive 'msalruntime_x86.dll'
        $script:otherDll = Join-Path $TestDrive 'NotAnAssembly.dll'
        foreach ($file in @($msalCopy, $otherDll)) { [System.IO.File]::WriteAllBytes($file, [byte[]](0..255)) }
        $script:msalRecord = Get-LoadFailureRecord -Path $msalCopy
        $script:otherRecord = Get-LoadFailureRecord -Path $otherDll
        $Error.Clear()
        Write-Error 'unrelated failure' -ErrorAction SilentlyContinue
        $script:unrelatedRecord = $Error[0]
    }

    It 'produces a genuine msalruntime BadImageFormatException record to test against' {
        $msalRecord | Should -Not -BeNullOrEmpty
        $msalRecord.FullyQualifiedErrorId | Should -Be 'BadImageFormatException'
        $msalRecord.Exception.ToString() | Should -Match 'msalruntime_x86\.dll'
    }

    It 'removes only the msalruntime load failures' {
        $result = @(Select-ActionableError -ErrorRecord @($msalRecord, $otherRecord, $unrelatedRecord, $msalRecord))
        $result.Count | Should -Be 2
        $result[0] | Should -Be $otherRecord
        $result[1] | Should -Be $unrelatedRecord
    }

    It 'keeps a BadImageFormatException for a non-MSAL file' {
        @(Select-ActionableError -ErrorRecord @($otherRecord)).Count | Should -Be 1
    }

    It 'handles bare exceptions and empty input' {
        $bare = [System.BadImageFormatException]::new('bad format', 'C:\x\msalruntime.dll')
        @(Select-ActionableError -ErrorRecord @($bare)).Count | Should -Be 0
        @(Select-ActionableError -ErrorRecord @([System.InvalidOperationException]::new('real'))).Count | Should -Be 1
        @(Select-ActionableError -ErrorRecord @()).Count | Should -Be 0
        @(Select-ActionableError -ErrorRecord $null).Count | Should -Be 0
    }

    It 'is applied before the closing error count' {
        $source = Get-Content (Resolve-Path "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp.psm1") -Raw
        $source | Should -Match '(?s)Select-ActionableError -ErrorRecord @\(\$Data\.Error\).*closed with \$\(\$Data\.Error\.Count\) error'
    }
}
