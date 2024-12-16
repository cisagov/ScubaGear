function Invoke-OpaCheck {
  <#
    .SYNOPSIS
      Runs an OPA check that to check Rego source files for parse and compilation errors.
    .PARAMETER $Paths
      The array of paths for OPA to check.
  #>
  [CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string[]]
		$Paths
	)

  Write-Warning "Checking paths with OPA..."
  Write-Warning " "

  foreach ($Path in $Paths) {
    opa test $Path # --strict
  }
}