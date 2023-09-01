# Increase PowerShell Maximum Function Count to support version 5.1 limitation
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MaximumFunctionCount')]
$MaximumFunctionCount = 32767

# Fallback in case the first assignment doesn't execute for some latent reasons
$Global:MaximumFunctionCount = 32767
