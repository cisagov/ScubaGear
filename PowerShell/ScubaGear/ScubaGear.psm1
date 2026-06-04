Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfig/ScubaConfig.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Orchestrator.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Connection/Connection.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Permissions/PermissionsHelper.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfigApp/ScubaConfigApp.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Support/ServicePrincipal.psm1')

# Register tab completers for M365Environment and ProductNames across all ScubaGear functions.
# Values are sourced from ScubaConfigSchema.json and ScubaConfigDefaults.json via the ScubaConfig class.
# Adding a new environment or product to those JSON files automatically updates completion and validation here.

$m365Completer = {
    param($cmd, $param, $word, $ast, $fakeBound)
    [ScubaConfig]::GetSupportedEnvironments() | Where-Object { $_ -like "$word*" }
}

$productCompleter = {
    param($cmd, $param, $word, $ast, $fakeBound)
    (@([ScubaConfig]::ScubaDefault('AllProductNames')) + '*') | Where-Object { $_ -like "$word*" }
}

# Get all functions in the ScubaGear module that have an M365Environment parameter
$m365Functions = Get-Command -CommandType Function |
    Where-Object { $_.Module.Path -like '*Scuba*' -and $_.Parameters.ContainsKey('M365Environment') } |
    Select-Object -ExpandProperty Name

# Get all functions in the ScubaGear module that have a ProductNames parameter
$productFunctions = Get-Command -CommandType Function |
    Where-Object { $_.Module.Path -like '*Scuba*' -and $_.Parameters.ContainsKey('ProductNames') } |
    Select-Object -ExpandProperty Name

# Register the completers for M365Environment across all relevant functions.
foreach ($fn in $m365Functions) {
    Register-ArgumentCompleter -CommandName $fn -ParameterName 'M365Environment' -ScriptBlock $m365Completer
}

# Register the completer for ProductNames across all relevant functions.
foreach ($fn in $productFunctions) {
    Register-ArgumentCompleter -CommandName $fn -ParameterName 'ProductNames' -ScriptBlock $productCompleter
}