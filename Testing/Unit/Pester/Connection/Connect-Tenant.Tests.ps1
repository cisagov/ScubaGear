BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1
}

Describe 'Connect-Tenant' {
    It 'Given 2 parameters, a list of product names and an endpoint, connects to each products backend' {
        $List = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
        while (Connect-Tenant -ProductNames $List -M365Environment 'gcc') {
            $LASTEXITCODE | Should -Be 0
        }
    }
}