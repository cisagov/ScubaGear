BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1
}

Describe 'Disconnect-Tenant' {
    It 'Takes no parameters and disconnects from the tenants' {
        Disconnect-Tenant
        $LASTEXITCODE | Should -Be 0
    }
}
