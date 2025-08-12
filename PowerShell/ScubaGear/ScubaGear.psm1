Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Orchestrator.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Connection/Connection.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/Permissions/PermissionsHelper.psm1')
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath './Modules/ScubaConfig/ScubaConfigAppUI.psm1') -Force