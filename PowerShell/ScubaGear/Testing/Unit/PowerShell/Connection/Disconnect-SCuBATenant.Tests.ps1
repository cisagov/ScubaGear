BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Connection.psm1') -Function 'Disconnect-SCuBATenant' -Force
}

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            function Disconnect-MgGraph {throw 'this will be mocked'}
            Mock -ModuleName Connection Disconnect-MgGraph {}
            # EXO now uses REST API - no ExchangeOnline module disconnect needed
            # SharePoint uses REST API - no SPO module disconnect needed
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            Disconnect-SCuBATenant -ErrorAction SilentlyContinue
            Should -Invoke -ModuleName Connection -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
        It 'Disconnects with verbose cleanup options' {
            Disconnect-SCuBATenant -ErrorAction SilentlyContinue -Verbose
            Should -Invoke -ModuleName Connection -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
        It 'Disconnects from all products' {
            {Disconnect-SCuBATenant} | Should -Not -Throw
            Should -Invoke -ModuleName Connection -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}