BeforeDiscovery{
    $ModuleBasePath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..' -Resolve)
    . (Join-Path -Path $ModuleBasePath -ChildPath "ScubaDefaults.ps1")
}

Describe "Verify Constants <Name>" -ForEach @(
    @{Name='DefaultOPAPath'; Expected=$true},
    @{Name='BadName'; Expected=$false}
){
    It "Check for <Name>" {
        $Result = Get-ScubaDefault -Name $Name
        $null -ne $Result | Should -Be $Expected -Because "value: $Results"
    }
}
