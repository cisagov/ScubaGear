# Increase PowerShell Maximum Function Count to support version 5.1 limitation
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MaximumFunctionCount')]
$MaximumFunctionCount = 32767

# Fallback in case the first assignment doesn't execute for some latent reasons
# PSScriptAnalyzer also is not supressing this warning even with this attribute
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:MaximumFunctionCount', Scope='Function')]
$Global:MaximumFunctionCount = 32767
