Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Orchestrator.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Connection/Connection.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Permissions/PermissionsHelper.psm1')
# The configuration editor is a WPF (Windows Presentation Foundation) app and only loads on Windows.
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfigApp/ScubaConfigApp.psm1')
}
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Support/ServicePrincipal.psm1')