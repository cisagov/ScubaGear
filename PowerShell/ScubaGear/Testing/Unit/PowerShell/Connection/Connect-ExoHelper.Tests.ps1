BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-EXOHelper' -Force
    Write-Debug $ModuleRootPath
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-EXOHelper' -ForEach @(
        @{Endpoint = 'commercial'}
        @{Endpoint = 'gcc'}
        @{Endpoint = 'gcchigh'}
        @{Endpoint = 'dod'}
    ){
        BeforeAll {
            function Connect-ExchangeOnline {throw 'this will be mocked'}
            Mock -ModuleName ConnectHelpers Connect-ExchangeOnline {}
        }
        It 'When connecting interactively to <Endpoint> endpoint, connects to Exchange Online' {
            Connect-EXOHelper -M365Environment $Endpoint
            Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-ExchangeOnline -Times 1
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}