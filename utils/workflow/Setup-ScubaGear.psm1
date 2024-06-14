function Setup-ScubaGear
{
  Import-Module -Name .\PowerShell\ScubaGear
  Initialize-SCuBA
}

Export-ModuleMember -Function
{
  'Setup-ScubaGear'
}