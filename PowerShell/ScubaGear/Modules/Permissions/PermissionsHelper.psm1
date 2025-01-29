Function Get-ScubaGearPermissions {
    <#
    .SYNOPSIS
        This Function is used to retrieve the permissions of the SCuBAGear module

    .DESCRIPTION
        This Function is used to retrieve the permissions of the SCuBAGear module

    .PARAMETER Domain
        The domain to be used in the apiResource

    .PARAMETER CmdletName
        The name of the cmdlet for which the permissions are to be retrieved

    .PARAMETER PermissionLevel
        The level of permission to be retrieved. The possible values are 'least' and 'higher'. Default is 'least'

    .PARAMETER ServicePrincipal
        The switch to indicate that the permissions are to be retrieved for a service principal

    .PARAMETER Product
        The product for which the permissions are to be retrieved. Options are 'aad', 'exo', 'defender', 'teams', 'sharepoint'. Can be an array of products and used in pipeline

    .PARAMETER Environment
        The Environment for which the permissions are to be retrieved. Options are 'commercial', 'gcc', 'gcchigh', 'dod'. Default is 'commercial'

    .PARAMETER OutAs
        The output format. The possible values are 'perms', 'endpoint', 'modules', 'api', 'support'. Default is 'perms'

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySettings

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySettings -PermissionLevel higher

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs all

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaPrivilegedAccessResource -OutAs support

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaGroupMember -OutAs api -id '559aabe6-7ef4-4fb6-b271-fa3d19e76017'

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad
        Get-ScubaGearPermissions -Product exo
        Get-ScubaGearPermissions -Product scubatank

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaUser -OutAs modules

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs modules

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -servicePrincipal

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -servicePrincipal

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -OutAs appId

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -OutAs endpoint

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs api -id '559aabe6-7ef4-4fb6-b271-fa3d19e76017'

    .EXAMPLE
        Get-ScubaGearPermissions -Product sharepoint -OutAs endpoint -Environment gcchigh -Domain contoso

    .EXAMPLE
        Get-ScubaGearPermissions -OutAs endpoint -Domain contoso

    .EXAMPLE
        'teams' | Get-ScubaGearPermissions -OutAs role

    .EXAMPLE
        'aad','scubatank' | Get-ScubaGearPermissions

    .NOTES
        NAME: Get-ScubaGearPermissions
        VERSION: 1.9

        USE TO FIND PERMS:
            (Find-MgGraphCommand -Command Get-MgBetaPolicyRoleManagementPolicyAssignment).Permissions | Select Name, IsLeastPrivilege
            Find-MgGraphPermission -All

        CHANGELOG:
        2024-10-03 - Initial version
        2024-11-05 - Added support for ServicePrincipal with id's and typos
        2024-11-07 - Added support for Domain, and beta api.
        2024-11-15 - Removed redundantpermissions and added verbose messages
        2024-12-20 - Added version and changelog. Added support for pipeline and for multiple products. Fixed issue with role output for null values
        2024-12-23 - Adjusted endpoint output based on structure changes in the permissions file
    #>

    [CmdletBinding(DefaultParameterSetName = 'CmdletName')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'CmdletName')]
        [Alias('Command')]
        [string]$CmdletName,

        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePrincipal')]
        [switch]$ServicePrincipal,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal',ValueFromPipeline=$true)]
        [ValidateSet('aad', 'exo', 'defender', 'teams', 'sharepoint', 'scubatank')]
        [string[]]$Product,

        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [guid]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('least', 'higher')]
        [Alias('PermissionType')]
        [string]$PermissionLevel = 'least',

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial',

        [Parameter(Mandatory = $false)]
        [ValidateSet('perms','modules', 'api', 'endpoint', 'support', 'role' , 'appId', 'all')]
        [string]$OutAs ='perms'
    )
    Begin{
        $ErrorActionPreference = 'Stop'

        iF($OutAs -eq "endpoint" -and $Product -eq 'sharepoint' -and !$Domain){
            Write-Error -Message "Parameter [-Domain] is required when OutAs is endpoint"
        }

        If($OutAs -eq 'api' -and $Product -match 'aad|teams' -and !$Id){
            Write-Error -Message "Parameter [-id] is required when OutAs is api or endpoint and Product is aad or teams"
        }

        [string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]

        $permissionSet = Get-Content -Path "$ResourceRoot\ScubaGearPermissions.json" | ConvertFrom-Json
        Write-Verbose "Command: `$permissionSet = Get-Content -Path '$ResourceRoot\ScubaGearPermissions.json' | ConvertFrom-Json"

        $ResourceAPIHash = @{
            'aad'        = '00000003-0000-0000-c000-000000000000'
            'exo'        = '00000002-0000-0ff1-ce00-000000000000'
            'defender'   = '00000002-0000-0ff1-ce00-000000000000'
            'sharepoint' = '00000003-0000-0ff1-ce00-000000000000'
            'scubatank'  = '00000003-0000-0000-c000-000000000000'
        }

        # Start with an empty array to build the filter
        $conditions = @()
        $conditionsmsg = @()
        $output = @()
    }
    Process{

        switch($PSBoundParameters.Keys){
            'CmdletName' {
                $conditions += {$_.moduleCmdlet -eq $CmdletName}
                $conditionsmsg += '`$_.moduleCmdlet -eq "' + $CmdletName + '"'
            }

            'Product' {
                Foreach($ProductItem in $Product){
                    $conditions += {$_.scubaGearProduct -contains $ProductItem }
                    $conditionsmsg = '`$_.scubaGearProduct -contains "' + $ProductItem + '"'
                    If($ServicePrincipal -and $ProductItem -ne 'teams'){
                        # Filter the resourceAPIAppId based on the product
                        $conditions += {$_.resourceAPIAppId -contains $ResourceAPIHash[$ProductItem]}
                        $conditionsmsg += '`$_.resourceAPIAppId -contains "' + $ResourceAPIHash[$ProductItem] + '"'
                    }elseif($OutAs -eq 'endpoint'){
                        #do no filter the resourceAPIAppId
                    }elseif($ProductItem -match 'exo|sharepoint|defender'){
                        # If the product is exo or SharePoint, then the resourceAPIAppId should not match the Exchange/SharePoint resourceAPIAppId
                        # This accounts for interactive permissions needed for Exchange when running the SCuBAGear, and doesn't list SharePoint interactive permissions
                        $conditions += {$_.resourceAPIAppId -notcontains $ResourceAPIHash[$ProductItem]}
                        $conditionsmsg += '`$_.resourceAPIAppId -notcontains "' + $ResourceAPIHash[$ProductItem] + '"'
                    }
                }
            }
        }

        foreach ($EnvironmentItem in $Environment) {
            $conditions += {$_.supportedEnv -contains $EnvironmentItem }
            $conditionsmsg += '`$_.supportedEnv -contains "' + $EnvironmentItem + '"'
        }

        #write a verbose statement where the values are expanded in the $conditions
        # the $_ causes the join to fail, so we need to replace it with another character
        $filterCondition = $conditionsmsg -join '' -replace '`', ' -and ' -replace '^\s+(-and)\s+', ''

        # Correct verbose message with escaped braces
        Write-Verbose -Message ("Command: `$collection = `$permissionSet | Where-Object {{ {0} }}" -f $filterCondition)

        # Combine the conditions into a single script block
        $filterScript = {
            $result = $true
            foreach ($condition in $conditions) {
                $result = $result -and (&$condition)
            }
            return $result
        }

        $collection = $permissionSet | Where-Object $filterScript

        # Apply the dynamically built filter in Where-Object
        switch ($OutAs) {
            'perms' {
                If($PermissionLevel -eq 'least'){
                    Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty leastPermissions -Unique"
                    $output += $collection | Select-Object -ExpandProperty leastPermissions -Unique
                }
                else{
                    Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty higherPermissions -Unique"
                    $output += $collection | Select-Object -ExpandProperty higherPermissions -Unique
                }
            }
            'modules' {
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty poshModule -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty poshModule -Unique
            }
            'endpoint' {

                #only get the api
                Write-Verbose -Message "Command: `$collection | Where-Object {`$_.moduleCmdlet -like 'Connect-*'} | foreach-object {`$_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain} | Select-Object -Unique"
                #combine the apiResource and api filter if exists
                $output += $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -like 'Connect-*'} | foreach-object {
                    #$apiResource = $_.'apiResource'

                    If($_.apifilter){
                        ($_.apiResource -replace "{id}",$Id -replace '{domain}',$Domain) + '?$filter=' + $_.apifilter
                    }else{
                        $_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain
                    }
                } | Select-Object -Unique

            }
            'api'{

                If($PSBoundParameters.ContainsKey('CmdletName') -and $CmdletName -match '-Mg'){
                    #if cmdlete is a graph cmdlet, then get the connect-* cmdlet
                    Write-Verbose -Message "Command: `$connecturi = `$permissionSet | Where-Object {`$_.moduleCmdlet -eq 'Connect-MgGraph' -and `$_.supportedEnv -eq '$Environment'} | foreach-object {`$_.apiResource} | Select-Object -Unique"
                    $connecturi = $permissionSet | Where-Object {$_.moduleCmdlet -eq 'Connect-MgGraph' -and $_.supportedEnv -eq $Environment} | foreach-object {$_.apiResource} | Select-Object -Unique
                }Else{
                    #get the connect-* cmdlet:
                    Write-Verbose -Message "Command: `$connecturi = `$collection | Where-Object {`$_.moduleCmdlet -like 'Connect-*'} | foreach-object {`$_.apiResource} | Select-Object -Unique"
                    $connecturi = $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -like 'Connect-*'} | foreach-object {$_.apiResource} | Select-Object -Unique
                }

                #only get the api
                Write-Verbose -Message "Command: `$collection | Where-Object {`$_.moduleCmdlet -notlike 'Connect-*'} | foreach-object {'$connecturi + ($_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain)'} | Select-Object -Unique"
                #combine the apiResource and api filter if exists
                $output += $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -notlike 'Connect-*'} | foreach-object {
                    #$apiResource = $_.'apiResource'

                    If($_.apifilter){
                        $connecturi + ($_.apiResource -replace "{id}",$Id -replace '{domain}',$Domain) + '?$filter=' + $_.apifilter
                    }else{
                        $connecturi + $_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain
                    }
                } | Select-Object -Unique

            }
            'support' {
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty supportLinks -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty supportLinks -Unique
            }
            'appId'{
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty resourceAPIAppId -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty resourceAPIAppId -Unique
            }
            'role' {
                Try{
                    Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty sprolePermissions -Unique"
                    $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty sprolePermissions -Unique
                }Catch{
                    $output += $null
                }
            }
            'all' {
                Write-Verbose -Message "Command: `$collection | Sort-Object"
                $objects += $collection | Where-Object $filterScript

                #replace domain and id if found in objects
                foreach ($object in $objects) {
                    $properties = $object.PSObject.Properties
                    foreach ($property in $properties) {
                        if ($property.Value -is [string]) {
                            # Replace in string values
                            $property.Value = $property.Value -replace '{domain}', 'contoso'
                        } elseif ($property.Value -is [array]) {
                            # Replace in array values while keeping it as an array
                            $property.Value = @($property.Value | ForEach-Object {
                                if ($_ -is [string]) {
                                    $_ -replace '{domain}', 'contoso'
                                } else {
                                    $_
                                }
                            })
                        }
                    }
                }

                $output = $objects
            }
        }
    }
    End{
        return $output | Sort-Object
    }
}


Function Get-ScubaGearEntraRedundantPermissions{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$FilterRedundancy
    )

    $data = Get-ScubaGearPermissions -Product aad -OutAs all

    ForEach($FirstItem in $data)
    {
        Write-Verbose "First loop [$($FirstItem.moduleCmdlet)] and HigherPermission: [$($FirstItem.higherPermissions)]  and LeastPermission: [$($FirstItem.leastPermissions)]"
        ForEach($SecondItem in $data)
        {
            Write-Verbose "  Second loop $($SecondItem.moduleCmdlet) and LeastPermission: $($SecondItem.leastPermissions)"
            if($SecondItem.moduleCmdlet -ne $FirstItem.moduleCmdlet `
                -and $SecondItem.scubaGearProduct -eq $FirstItem.scubaGearProduct `
                -and $SecondItem.higherPermissions -contains $FirstItem.leastPermissions `
                -and $FirstItem.leastPermissions -ne $SecondItem.leastPermissions `
                -and $SecondItem.PermissionNeeded -eq "false"
                )
            {
                Write-Verbose "  - Match found [$($FirstItem.moduleCmdlet)] and [$($SecondItem.moduleCmdlet)] with: [$($FirstItem.leastPermissions) and $($SecondItem.higherPermissions)]"
                # Create node in json named redundant and set value to true
                #$SecondItem.permissionredunancy = "true"
                #$SecondItem.redundantcmdlet = $FirstItem.moduleCmdlet
                #added permissionredunancy member to the object dynamically

                $SecondItem | Add-Member -MemberType NoteProperty -Name PermissionNeeded -Value "false" -Force
                $SecondItem | Add-Member -MemberType NoteProperty -Name RedundantCmdlet -Value $FirstItem.moduleCmdlet -Force

                $data += $FirstItem
            }
        }
    }

    #filter out connect
    $data = $data | Where-Object {$_ -notmatch 'Connect'}

    If($FilterRedundancy){
        return $data | Where-Object {$_.PermissionNeeded -ne "false"} | Select -ExpandProperty leastPermissions -Unique | Sort
    }Else{
        return $data| Select moduleCmdlet,RedundantCmdlet,PermissionNeeded,leastPermissions
    }
}
<#
$leastPermissions = Get-ScubaGearPermissions -Product aad -PermissionLevel least
$higherPermissions = Get-ScubaGearPermissions -Product aad -PermissionLevel higher
$redundantPermissions = Get-ScubaGearEntraRedundantPermissions
#Compare the two and populate only the least privileges that does not exist in higher
$onlyLeastPrivileges = $leastPermissions | Where-Object {$_ -notin $higherPermissions}
#>


Export-ModuleMember -Function Get-ScubaGearPermissions,Get-ScubaGearEntraRedundantPermissions