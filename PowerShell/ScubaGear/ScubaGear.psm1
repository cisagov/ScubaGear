Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfig/ScubaConfig.psm1')

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Orchestrator.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Connection/Connection.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Permissions/PermissionsHelper.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfigApp/ScubaConfigApp.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Support/ServicePrincipal.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Diff/Diff.psm1')

# Argument completers for M365Environment and ProductNames parameters
$m365Completer = {
	param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
	$null = $CommandName, $ParameterName, $CommandAst, $FakeBoundParameters
	& (Get-Module ScubaConfig) { [ScubaConfig]::GetSupportedEnvironments() } |
		Where-Object { $_ -like "$WordToComplete*" }
}

# Argument completer for ProductNames parameter
$productCompleter = {
	param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
	$null = $CommandName, $ParameterName, $CommandAst, $FakeBoundParameters
	& (Get-Module ScubaConfig) { [ScubaConfig]::GetAllValidProductNames() } |
		Where-Object { $_ -like "$WordToComplete*" }
}

# Register argument completers for all module functions that have M365Environment or ProductNames parameters
$moduleFunctions = Get-Command -CommandType Function |
	Where-Object { $_.Module.Path -like "$PSScriptRoot*" }
foreach ($moduleFunction in $moduleFunctions) {
    # Check if the function has M365Environment or ProductNames parameters and register the appropriate argument completers
	if ($moduleFunction.Parameters.ContainsKey('M365Environment')) {
		Register-ArgumentCompleter -CommandName $moduleFunction.Name -ParameterName 'M365Environment' -ScriptBlock $m365Completer
	}
    # Check if the function has ProductNames parameter and register the argument completer
	if ($moduleFunction.Parameters.ContainsKey('ProductNames')) {
		Register-ArgumentCompleter -CommandName $moduleFunction.Name -ParameterName 'ProductNames' -ScriptBlock $productCompleter
	}
}