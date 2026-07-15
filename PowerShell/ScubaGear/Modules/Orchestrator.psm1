using module 'ScubaConfig\ScubaConfig.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Utility/ScubaLogging.psm1")

function Invoke-SCuBA {
    <#
    .SYNOPSIS
    Execute the SCuBAGear tool security baselines for specified M365 products.
    .Description
    This is the main function that runs the Providers, Rego, and Report creation all in one PowerShell script call.
    .Parameter ProductNames
    A list of one or more M365 shortened product names that the tool will assess when it is executed. Acceptable product name values are listed below.
    To assess Azure Active Directory you would enter the value aad.
    To assess Exchange Online you would enter exo and so forth.
    - Azure Active Directory: aad
    - Defender for Office 365: defender
    - Exchange Online: exo
    - MS Power Platform: powerplatform
    - SharePoint Online: sharepoint
    - MS Teams: teams.
    Use '*' to run all baselines.
    .Parameter M365Environment
    This parameter is used to authenticate to the different commercial/government environments.
    Valid values include "commercial", "gcc", "gcchigh", or "dod".
    - For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    - For M365 Government Community Cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    - For M365 Government Community Cloud High tenants enter the value **"gcchigh"**.
    - For M365 Department of Defense tenants enter the value **"dod"**.
    Default value is 'commercial'.
    .Parameter OPAPath
    The folder location of the OPA Rego executable file.
    The OPA Rego executable embedded with this project is located in the project's root folder.
    If you want to execute the tool using a version of OPA Rego located in another folder,
    then customize the variable value with the full path to the alternative OPA Rego exe file.
    .Parameter LogIn
    A `$true` or `$false` variable that if set to `$true`
    will prompt you to provide credentials if you want to establish a connection
    to the specified M365 products in the **$ProductNames** variable.
    For most use cases, leave this variable to be `$true`.
    A connection is established in the current PowerShell terminal session with the first authentication.
    If you want to run another verification in the same PowerShell session simply set
    this variable to be `$false` to bypass the reauthenticating in the same session. Default is $true.
    Note: defender will ask for authentication even if this variable is set to `$false`
    .Parameter Version
    Will output the current ScubaGear version to the terminal without running this cmdlet.
    .Parameter AppID
    The application ID of the service principal that's used during certificate based
    authentication. A valid value is the GUID of the application ID (service principal).
    .Parameter CertificateThumbprint
    The thumbprint value specifies the certificate that's used for certificate base authentication.
    The underlying PowerShell modules retrieve the certificate from the user's certificate store.
    As such, a copy of the certificate must be located there.
    .Parameter Organization
    Specify the organization that's used in certificate based authentication.
    Use the tenant's tenantname.onmicrosoft.com domain for the parameter value.
    .Parameter OutPath
    The folder path where both the output JSON and the HTML report will be created.
    The folder will be created if it does not exist. Defaults to current directory.
    .Parameter OutFolderName
    The name of the folder in OutPath where both the output JSON and the HTML report will be created.
    Defaults to "M365BaselineConformance". The client's local timestamp will be appended.
    .Parameter OutProviderFileName
    The name of the Provider output JSON created in the folder created in OutPath.
    Defaults to "ProviderSettingsExport".
    .Parameter OutRegoFileName
    The name of the Rego output JSON and CSV created in the folder created in OutPath.
    Defaults to "TestResults".
    .Parameter OutReportName
    The name of the main html file page created in the folder created in OutPath.
    Defaults to "BaselineReports".
    .Parameter KeepIndividualJSON
    Keeps ScubaGear legacy output where files are not merged into an all in one JSON.
    This parameter is for backwards compatibility for those working with the older ScubaGear output files.
    .Parameter OutJsonFileName
    If KeepIndividualJSON is not set, the name of the consolidated json created in the folder
    created in OutPath. Defaults to "ScubaResults". The report UUID will be appended to this.
    .Parameter OutCsvFileName
    The CSV created in the folder created in OutPath that contains the CSV version of the test results.
    Defaults to "ScubaResults".
    .Parameter OutActionPlanFileName
    The CSV created in the folder created in OutPath that contains a CSV template prepopulated with the failed
    SHALL controls with fields for documenting failure causes and remediation plans. Defaults to "ActionPlan".
    .Parameter DisconnectOnExit
    Set switch to disconnect all active connections on exit from ScubaGear (default: $false)
    .Parameter ConfigFilePath
    Local file path to a JSON or YAML formatted configuration file.
    Configuration file parameters can be used in place of command-line
    parameters. Additional parameters and variables not available on the
    command line can also be included in the file that will be provided to the
    tool for use in specific tests.
    .Parameter DarkMode
    Set switch to enable report dark mode by default.
    .Parameter Quiet
    Do not launch external browser for report.
    .Parameter SilenceBODWarnings
    Do not warn for requirements specific to BOD compliance (e.g., documenting OrgName in the config file).
    .Parameter NumberOfUUIDCharactersToTruncate
    Controls how many characters will be truncated from the report UUID when appended to the end of OutJsonFileName.
    Valid values are 0, 13, 18, 36
    .Parameter PreferredDnsResolvers
    IP addresses of DNS resolvers that should be used to retrieve any DNS
    records required by specific SCuBA policies. Optional; if not provided, the
    system default will be used.
    .Parameter SkipDoH
    If true, do not fallback to DoH should the traditional DNS requests fail
    when retrieving any DNS records required by specific SCuBA policies.
    .Parameter Transcript
    Enable PowerShell transcript logging for complete console output capture. When specified, a transcript log file will be created in addition to the default ScubaDebug log.
    Note: Debug logs are always created in the output folder's DebugLogs subfolder.
    .Example
    Invoke-SCuBA
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformance_*.
    .Example
    Invoke-SCuBA -Version
    This example returns the version of SCuBAGear.
    .Example
    Invoke-SCuBA -ConfigFilePath MyConfig.json
    This example uses the specified configuration file when executing SCuBAGear.
    .Example
    Invoke-SCuBA -ProductNames aad, defender -OPAPath . -OutPath .
    The example will run the tool against the Azure Active Directory, and Defender security
    baselines.
    .Example
    Invoke-SCuBA -ProductNames * -M365Environment dod -OPAPath . -OutPath .
    This example will run the tool against all available security baselines with the
    'dod' teams endpoint.
    .Example
    Invoke-SCuBA -ProductNames aad,exo -M365Environment gcc -OPAPath . -OutPath . -DisconnectOnExit
    Run the tool against Entra Id and Exchange Online security
    baselines, disconnecting connections for those products when complete.
    .Example
    Invoke-SCuBA -ProductNames * -CertificateThumbprint <insert-thumbprint> -AppID <insert-appid> -Organization "tenant.onmicrosoft.com"
    This example will run the tool against all available security baselines while authenticating using a Service Principal with the CertificateThumprint bundle of parameters.
    .Functionality
    Public
    #>
    [CmdletBinding(DefaultParameterSetName='Report')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = [ScubaConfig]::ScubaDefault('DefaultProductNames'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = [ScubaConfig]::ScubaDefault('DefaultLogIn'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DisconnectOnExit,

        [Parameter(ParameterSetName = 'VersionOnly')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = [ScubaConfig]::ScubaDefault('DefaultOutPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderName = [ScubaConfig]::ScubaDefault('DefaultOutFolderName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = [ScubaConfig]::ScubaDefault('DefaultOutProviderFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = [ScubaConfig]::ScubaDefault('DefaultOutRegoFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = [ScubaConfig]::ScubaDefault('DefaultOutReportName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $KeepIndividualJSON,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName = [ScubaConfig]::ScubaDefault('DefaultOutJsonFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName = [ScubaConfig]::ScubaDefault('DefaultOutCsvFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName = [ScubaConfig]::ScubaDefault('DefaultOutActionPlanFileName'),

        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-Not ($_ | Test-Path)){
                throw "SCuBA configuration file or folder does not exist. $_"
            }
            if (-Not ($_ | Test-Path -PathType Leaf)){
                throw "SCuBA configuration Path argument must be a file."
            }
            return $true
        })]
        [System.IO.FileInfo]
        $ConfigFilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $SilenceBODWarnings,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate = [ScubaConfig]::ScubaDefault('DefaultNumberOfUUIDCharactersToTruncate'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [AllowEmptyCollection()]
        [string[]]
        $PreferredDnsResolvers = [ScubaConfig]::ScubaDefault('DefaultPreferredDnsResolvers'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $SkipDoH = [ScubaConfig]::ScubaDefault('DefaultSkipDoH'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Transcript
    )
    process {
        # Retrieve ScubaGear Module versions
        $ParentPath = Split-Path $PSScriptRoot -Parent -ErrorAction 'Stop'
        $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $ParentPath -ChildPath 'ScubaGear.psd1' -Resolve) -ErrorAction 'Stop'
        $ModuleVersion = $ScubaManifest.ModuleVersion
        if ($Version) {
            Write-Output("SCuBA Gear v$ModuleVersion")
            return
        }

        # Initialize logging flag - actual initialization happens after output folder is created
        $Script:ScubaLoggingEnabled = $false

        # Transform ProductNames into list of all products if it contains wildcard
        if ($ProductNames.Contains('*')){
            $ProductNames = $PSBoundParameters['ProductNames'] = "aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams", "powerbi"
            Write-Debug "Setting ProductName to all products because of wildcard"
        }

        # defender is an alias for securitysuite, substitute securitysuite in for defender if specified
        if ($ProductNames.Contains('defender')){
            if (-not $ProductNames.Contains('securitysuite')) {
                $ProductNames = $PSBoundParameters['ProductNames'] = $ProductNames + "securitysuite"
            }
            $ProductNames = $PSBoundParameters['ProductNames'] = @($ProductNames | Where-Object {$_ -ne "defender" })
            Write-Debug "Substituting defender with securitysuite in ProductNames"
        }

        # Default execution ParameterSet
        if ($PSCmdlet.ParameterSetName -eq 'Report'){

            $ProvidedParameters = @{
                'ProductNames' = $ProductNames | Sort-Object -Unique
                'M365Environment' = $M365Environment
                'OPAPath' = $OPAPath
                'LogIn' = $LogIn
                'DisconnectOnExit' = $DisconnectOnExit
                'OutPath' = $OutPath
                'OutFolderName' = $OutFolderName
                'OutProviderFileName' = $OutProviderFileName
                'OutRegoFileName' = $OutRegoFileName
                'OutReportName' = $OutReportName
                'KeepIndividualJSON' = $KeepIndividualJSON
                'OutJsonFileName' = $OutJsonFileName
                'OutCsvFileName' = $OutCsvFileName
                'OutActionPlanFileName' = $OutActionPlanFileName
                'NumberOfUUIDCharactersToTruncate' = $NumberOfUUIDCharactersToTruncate
                'AppID' = $AppID
                'CertificateThumbprint' = $CertificateThumbprint
                'Organization' = $Organization
                'PreferredDnsResolvers' = $PreferredDnsResolvers
                'SkipDoH' = $SkipDoH
            }

            $ScubaConfig = New-Object -Type PSObject -Property $ProvidedParameters
        }

        Remove-Resources # Unload helper modules if they are still in the PowerShell session
        Import-Resources # Imports Providers, RunRego, etc.

        # Loads and executes parameters from a Configuration file
        if ($PSCmdlet.ParameterSetName -eq 'Configuration'){
            [ScubaConfig]::ResetInstance()
            try {
                # Load config without validation to allow command-line parameter overrides
                if (-Not ([ScubaConfig]::GetInstance().LoadConfig($ConfigFilePath, $true))){
                    Write-Error -Message "The config file failed to load: $ConfigFilePath"
                    return
                }
                $ScubaConfig = [ScubaConfig]::GetInstance().Configuration
            }
            catch {
                # Display clean validation error without PowerShell stack trace
                Write-ScubaLog -Message "Configuration loading failed" -Level "Error" -Source "InvokeScuba" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                Write-Warning $_.Exception.Message
                return
            }

            # Authentications parameters use below
            $SPparams = 'AppID', 'CertificateThumbprint', 'Organization'

            # Bound parameters indicate a parameter has been passed in.
            # However authentication parameters are special and are not handled within
            # the config module (since you can't make a default).  If an authentication
            # parameter is set in the config file but not supplied on the command line
            # set the Bound parameters value which make it appear as if it was supplied on the
            # command line

            foreach ( $value in $SPparams )
            {
                if  ( $ScubaConfig[$value] -and  (-not  $PSBoundParameters[$value] )) {
                    $PSBoundParameters.Add($value, $ScubaConfig[$value])
                }
            }

            # Now the bound parameters contain the following
            # 1) Non Authentication Parameters explicitly passed in
            # 2) Authentication parameters ( passed in or from the config file as per code above )
            #
            # So to provide for a command line override of config values just set the corresponding
            # config value from the bound parameters to override.  This is redundant copy for
            # the authentication parameters ( but keeps the logic simpler)
            # We do not allow ConfigFilePath to be copied as it will be propagated to the
            # config module by reference and causes issues
            #
            foreach ( $value in $PSBoundParameters.keys ) {
                if ( $value -ne "ConfigFilePath" )
                {
                    $paramValue = $PSBoundParameters[$value]
                    # Convert SwitchParameter to bool for schema compatibility
                    if ($paramValue -is [System.Management.Automation.SwitchParameter]) {
                        $paramValue = $paramValue.ToBool()
                    }
                    $ScubaConfig[$value] = $paramValue
                }
            }

            # Validate the final configuration after all overrides have been applied
            try {
                [ScubaConfig]::GetInstance().ValidateConfiguration()
            }
            catch {
                # Display clean validation error without PowerShell stack trace
                Write-ScubaLog -Message "Configuration validation failed" -Level "Error" -Source "InvokeScuba" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                #Write-Warning $_.Exception.Message
                $Host.UI.WriteErrorLine("`nERROR: " + $_.Exception.Message)
                return
            }
        }

        if (-not $SilenceBODWarnings -and $null -eq $ScubaConfig.OrgName) {
            $Warning = "Config file option OrgName not provided. This option is required for BOD "
            $Warning += "submissions. See https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/configuration.md#scuba-compliance-use for more details. "
            $Warning += "This warning can be silenced with the -SilenceBODWarnings parameter"
            Write-Warning $Warning
        }

        if ($ScubaConfig.OutCsvFileName -eq $ScubaConfig.OutActionPlanFileName) {
            $ErrorMessage = "OutCsvFileName and OutActionPlanFileName cannot be equal to each other. "
            $ErrorMessage += "Both are set to $($ScubaConfig.OutCsvFileName). Stopping execution."
            throw $ErrorMessage
        }

        # Creates the output folder
        $Date = Get-Date -ErrorAction 'Stop'
        $FormattedTimeStamp = $Date.ToString("yyyy_MM_dd_HH_mm_ss")
        $OutFolderPath = $ScubaConfig.OutPath
        $FolderName = "$($ScubaConfig.OutFolderName)_$($FormattedTimeStamp)"
        New-Item -Path $OutFolderPath -Name $($FolderName) -ItemType Directory -ErrorAction 'Stop' | Out-Null
        $OutFolderPath = Join-Path -Path $OutFolderPath -ChildPath $FolderName -ErrorAction 'Stop'

        # Initialize logging for troubleshooting - debug logs are ALWAYS created
        # Logs are placed in a DebugLogs subfolder within the output folder
        # Transcript logging is optional and enabled only when -Transcript is specified
        try {
            # Create debug logs folder within the output folder
            $ScubaLogFolder = Join-Path -Path $OutFolderPath -ChildPath "DebugLogs"

            # Initialize logging WITH tracing for detailed logs
            # Transcript is only enabled if -Transcript switch was used
            if ($Transcript) {
                Initialize-ScubaLogging -LogPath $ScubaLogFolder -EnableTracing -LogLevel "Debug" -Transcript
                Write-Output "ScubaGear logging enabled with transcript"
            }
            else {
                Initialize-ScubaLogging -LogPath $ScubaLogFolder -EnableTracing -LogLevel "Debug"
            }

            #enable the scoped logging flag to indicate that logging is active for the rest of the execution.
            $Script:ScubaLoggingEnabled = $true
            Write-ScubaLog -Message "ScubaGear logging initialized" -Level "Info" -Source "InvokeScuba" -Data @{
                Version = $ModuleVersion
                ProductNames = ($ProductNames -join ', ')
                UserPassedEnvironment = $M365Environment
                OutputFolder = $OutFolderPath
                LogFolder = $ScubaLogFolder
                TranscriptEnabled = $Transcript
            }

            # Log cmdlet invocation details to capture how ScubaGear was invoked
            $InvocationParams = @{}
            foreach ($key in $PSBoundParameters.Keys) {
                # Mask sensitive values for security
                if ($key -in @('CertThumbprintParams', 'ClientSecretParams')) {
                    $InvocationParams[$key] = '***REDACTED***'
                }
                else {
                    $InvocationParams[$key] = $PSBoundParameters[$key]
                }
            }
            Write-ScubaLog -Message "Cmdlet invocation captured" -Level "Info" -Source "InvokeScuba" -Data @{
                Command = $MyInvocation.MyCommand.Name
                Parameters = $InvocationParams
                BoundParameterCount = $PSBoundParameters.Count
                InvocationLine = $MyInvocation.Line
            }

            # Capture environment diagnostics using Write-ScubaRunDetails
            Write-ScubaLog -Message "Capturing environment diagnostics" -Level "Info" -Source "InvokeScuba"
            try {
                Write-ScubaRunDetails -IncludeLoadedModules -IncludeErrors -ConfiguredOPAPath $ScubaConfig.OPAPath -ErrorAction Stop
            }
            catch {
                Write-ScubaLog -Message "Failed to capture environment diagnostics" -Level "Warning" -Source "InvokeScuba" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
            }
        }
        catch {
            Write-ScubaLog -Message "Failed to initialize ScubaGear logging" -Level "Warning" -Source "InvokeScuba" -Data @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }
            Write-Warning "Failed to initialize ScubaGear logging: $_"
            $Script:ScubaLoggingEnabled = $false
        }

        # If user is authenticating with service principal, automatically detect the M365Environment using Microsoft's openid-configuration API
        # This overrides any user provided command line value for M365Environment and the default value of "commercial"
        if ($ScubaConfig.CertificateThumbprint -or $ScubaConfig.AppID) {
            # Get-ServicePrincipalParams will validate that CertificateThumbprint, AppID, and Organization are all provided
            $null = Get-ServicePrincipalParams -ScubaConfig $ScubaConfig
            $ScubaConfig.M365Environment = Get-M365EnvironmentByDomain -TenantDomain $ScubaConfig.Organization
        }
        else {
            Write-Information "`nIf you are running v2.0.0 with interactive login against a non-commercial tenant such as gcc or gcchigh, include the -M365Environment parameter. In a future release ScubaGear will auto-detect the M365 environment and this won't be necessary.`n" -InformationAction Continue
        }

        # Product Authentication - parameters consolidated into ScubaConfig
        Write-ScubaLog -Message "Starting product authentication..." -Level "Info" -Source "InvokeScuba" -Data @{
            ProductNames = ($ScubaConfig.ProductNames -join ', ')
            M365Environment = $ScubaConfig.M365Environment
            UsesServicePrincipal = (-not [string]::IsNullOrEmpty($ScubaConfig.AppID))
        }

        $ConnectionResult = Invoke-Connection -ScubaConfig $ScubaConfig
        $ProdAuthFailed = $ConnectionResult.ProdAuthFailed
        if ($ProdAuthFailed.Count -gt 0) {
            Write-ScubaLog -Message "Some products failed authentication" -Level "Warning" -Source "InvokeScuba" -Data @{FailedProducts = ($ProdAuthFailed -join ', ')}

            # Check if ALL products failed authentication
            $Difference = Compare-Object $ScubaConfig.ProductNames -DifferenceObject $ProdAuthFailed -PassThru
            if (-not $Difference) {
                # All products failed - log critical error (triggers automatic report generation in Stop-ScubaLogging)
                Write-ScubaLog -Message "CRITICAL: All products failed authentication - aborting execution" -Level "Error" -Source "InvokeScuba" -Data @{
                    RequestedProducts = ($ScubaConfig.ProductNames -join ', ')
                    FailedProducts = ($ProdAuthFailed -join ', ')
                }
                # Stop logging and generate error report before exiting
                Stop-ScubaLogging
                return
            }

            # Some products succeeded - continue with the successful ones
            $ScubaConfig.ProductNames = $Difference
        }

        # Capture module snapshot after authentication to log what modules were imported
        if ($Script:ScubaLoggingEnabled) {
            try {
                Update-ScubaModuleSnapshot -SnapshotName "PostAuthentication"
            }
            catch {
                Write-ScubaLog -Message "Failed to capture post-authentication module snapshot" -Level "Warning" -Source "InvokeScuba" -Data @{
                    Error = $_.Exception.Message
                }
            }
        }

        # Tenant Metadata for the Report

        Write-ScubaLog -Message "Retrieving tenant details..." -Level "Info" -Source "InvokeScuba" -Data @{
            ProductNames = ($ScubaConfig.ProductNames -join ', ')
            M365Environment = $ScubaConfig.M365Environment
        }

        $TenantDetails = Get-TenantDetail -ProductNames $ScubaConfig.ProductNames -M365Environment $ScubaConfig.M365Environment -ConnectionResult $ConnectionResult
        Write-ScubaLog -Message "Tenant details retrieved successfully" -Level "Debug" -Source "InvokeScuba"

        # Generate a GUID to uniquely identify the output JSON
        $Guid = New-Guid -ErrorAction 'Stop'

        try {
            # Provider Execution
            # Provider parameters consolidated into ScubaConfig; remaining args passed explicitly
            Write-ScubaLog -Message "Starting provider execution..." -Level "Info" -Source "InvokeScuba" -Data @{
                ProductNames = ($ScubaConfig.ProductNames -join ', ')
                ModuleVersion = $ModuleVersion
                Guid = $Guid
            }

            $ProdProviderFailed = if ($Script:ScubaLoggingEnabled) {
                Trace-ScubaFunction -FunctionName "Invoke-ProviderList" -Parameters @{
                    ScubaConfig = "[ScubaConfig Object]"
                    TenantDetails = "[TenantDetails Object]"
                    ModuleVersion = $ModuleVersion
                    OutFolderPath = $OutFolderPath
                    Guid = $Guid
                    ConnectionResult = "[ConnectionResult Object]"
                } -LogReturnValue $true -ScriptBlock {
                    Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
                }
            }
            else {
                Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
            }

            if ($ProdProviderFailed.Count -gt 0) {
                Write-ScubaLog -Message "Some providers failed to execute" -Level "Warning" -Source "InvokeScuba" -Data @{FailedProducts = ($ProdProviderFailed -join ', ')}
                $ScubaConfig.ProductNames = Compare-ProductList -ProductNames $ScubaConfig.ProductNames `
                -ProductsFailed $ProdProviderFailed `
                -ExceptionMessage 'All indicated Product Providers failed to execute'
            }

            # OPA Rego invocation
            # Rego parameters consolidated into ScubaConfig; remaining args passed explicitly
            Write-ScubaLog -Message "Starting OPA Rego evaluation..." -Level "Info" -Source "InvokeScuba" -Data @{
                ProductNames = ($ScubaConfig.ProductNames -join ', ')
                OPAPath = $ScubaConfig.OPAPath
            }
            $ProdRegoFailed = if ($Script:ScubaLoggingEnabled) {
                Trace-ScubaFunction -FunctionName "Invoke-RunRego" -Parameters @{
                    ScubaConfig = "[ScubaConfig Object]"
                    ParentPath = $ParentPath
                    OutFolderPath = $OutFolderPath
                } -ScriptBlock {
                    Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath
                }
            }
            else {
                Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath
            }

            if ($ProdRegoFailed.Count -gt 0) {
                Write-ScubaLog -Message "Some Rego evaluations failed" -Level "Warning" -Source "InvokeScuba" -Data @{FailedProducts = ($ProdRegoFailed -join ', ')}

                $ScubaConfig.ProductNames = Compare-ProductList -ProductNames $ScubaConfig.ProductNames `
                -ProductsFailed  $ProdRegoFailed `
                -ExceptionMessage 'All indicated Product Rego invocations failed'
            }

            # Report Creation - using ScubaConfig for most settings
            # Converted back from JSON String for PS Object use
            Write-ScubaLog -Message "Starting report creation..." -Level "Info" -Source "InvokeScuba" -Data @{
                DarkMode = $DarkMode.IsPresent
                Quiet = $Quiet.IsPresent
                KeepIndividualJSON = $KeepIndividualJSON.IsPresent
            }

            $TenantDetails = $TenantDetails | ConvertFrom-Json
            if ($Script:ScubaLoggingEnabled) {
                Trace-ScubaFunction -FunctionName "Invoke-ReportCreation" -Parameters @{
                    ScubaConfig = "[ScubaConfig Object]"
                    TenantDetails = "[TenantDetails Object]"
                    ModuleVersion = $ModuleVersion
                    OutFolderPath = $OutFolderPath
                    DarkMode = $DarkMode
                    Quiet = $Quiet
                } -ScriptBlock {
                    Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode -Quiet:$Quiet
                }
            }
            else {
                Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode -Quiet:$Quiet
            }

            $FullNameParams = @{
                'OutJsonFileName'                  = $ScubaConfig.OutJsonFileName;
                'Guid'                             = $Guid;
                'NumberOfUUIDCharactersToTruncate' = $ScubaConfig.NumberOfUUIDCharactersToTruncate;
            }
            $FullScubaResultsName = Get-FullOutJsonName @FullNameParams

            if (-not $KeepIndividualJSON) {
                # Craft the complete json version of the output
                $JsonParams = @{
                    'ProductNames'         = $ScubaConfig.ProductNames;
                    'OutFolderPath'        = $OutFolderPath;
                    'OutProviderFileName'  = $ScubaConfig.OutProviderFileName;
                    'TenantDetails'        = $TenantDetails;
                    'ModuleVersion'        = $ModuleVersion;
                    'FullScubaResultsName' = $FullScubaResultsName;
                    'Guid'                 = $Guid;
                    'SilenceBODWarnings' = $SilenceBODWarnings;
                }
                Merge-JsonOutput @JsonParams
            }
            # Craft the csv version of just the results
            $CsvParams = @{
                'ProductNames'          = $ScubaConfig.ProductNames;
                'OutFolderPath'         = $OutFolderPath;
                'FullScubaResultsName'  = $FullScubaResultsName;
                'OutCsvFileName'        = $ScubaConfig.OutCsvFileName;
                'OutActionPlanFileName' = $ScubaConfig.OutActionPlanFileName;
            }
            ConvertTo-ResultsCsv @CsvParams
        }
        finally {
            if ($ScubaConfig.DisconnectOnExit) {
                if ($VerbosePreference -eq "Continue") {
                    Disconnect-SCuBATenant -ProductNames $ScubaConfig.ProductNames -ErrorAction SilentlyContinue -Verbose
                }
                else {
                    Disconnect-SCuBATenant -ProductNames $ScubaConfig.ProductNames -ErrorAction SilentlyContinue
                }
            }
            [ScubaConfig]::ResetInstance()

            # Clean up debug logging module
            try {
                Write-ScubaLog -Message "ScubaGear assessment completed! Check report in [$OutFolderPath]" -Level "Info" -Source "InvokeScuba"
                Stop-ScubaLogging
            }
            catch {
                Write-ScubaLog -Message "Failed to stop ScubaGear logging" -Level "Warning" -Source "InvokeScuba" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                $Script:ScubaLoggingEnabled = $false
            }

        }
    }
}

$ArgToProd = @{
    teams = "Teams";
    exo = "EXO";
    securitysuite = "SecuritySuite";
    aad = "AAD";
    powerplatform = "PowerPlatform";
    sharepoint = "SharePoint";
    powerbi = "PowerBI";
}

$ProdToFullName = @{
    Teams = "Microsoft Teams";
    EXO = "Exchange Online";
    SecuritySuite = "Security Suite";
    AAD = "Azure Active Directory";
    PowerPlatform = "Microsoft Power Platform";
    SharePoint = "SharePoint Online";
    PowerBI = "Microsoft Power BI";
}

$IndividualReportFolderName = "IndividualReports"

function Get-FileEncoding{
    <#
    .Description
    This function returns encoding type for setting content.
    .Functionality
    Internal
    #>
    $PSVersion = $PSVersionTable.PSVersion

    $Encoding = 'utf8'

    if ($PSVersion -ge '6.0'){
        $Encoding = 'utf8NoBom'
    }

    return $Encoding
}

function Invoke-ProviderList {
    <#
    .Description
    This function runs the various providers modules stored in the Providers Folder
    Output will be stored as a ProviderSettingsExport.json in the OutPath Folder
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $ScubaConfig,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TenantDetails,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

        [Parameter(Mandatory = $false)]
        [hashtable]
        $ConnectionResult
    )
    process {
        try {
            # yes the syntax has to be like this
            # fixing the spacing causes PowerShell interpreter errors
            $ProviderJSON = @"
"@
            $N = 0
            $Len = @($ScubaConfig.ProductNames).Count
            $ProdProviderFailed = @()
            $ConnectTenantParams = @{
                'M365Environment' = $ScubaConfig.M365Environment
            }
            $SPOProviderParams = @{
                'M365Environment' = $ScubaConfig.M365Environment
            }

            $ServicePrincipalAuth = $false
            if ($ScubaConfig.AppID) {
                $ServicePrincipalParams = Get-ServicePrincipalParams -ScubaConfig $ScubaConfig
                $ConnectTenantParams += @{ServicePrincipalParams = $ServicePrincipalParams; }
                $ServicePrincipalAuth = $true
                $SPOProviderParams += @{ServicePrincipalParams = $ServicePrincipalParams }
            }

            foreach ($Product in $ScubaConfig.ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N * 100 / $Len
                $Status = "Running the $($BaselineName) Provider; $($N) of $($Len) Product settings extracted"
                $ProgressParams = @{
                    'Activity' = "Running the provider for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams
                Write-ScubaLog -Message "Starting provider export: $BaselineName" -Level "Debug" -Source "ProviderList" -Data @{ Product = $Product; N = $N; Total = $Len }
                try {
                    $RetVal = ""
                    switch ($Product) {
                        "aad" {
                            $RetVal = Export-AADProvider -M365Environment $ScubaConfig.M365Environment | Select-Object -Last 1
                        }
                        "exo" {
                            $EXOProviderParams = @{
                                'PreferredDnsResolvers' = $ScubaConfig.PreferredDnsResolvers
                                'SkipDoH'              = $ScubaConfig.SkipDoH
                                'AccessToken'          = $ConnectionResult.EXOAccessToken
                                'ApiEndpoint'          = $ConnectionResult.EXOApiEndpoint
                            }
                            $RetVal = Export-EXOProvider @EXOProviderParams | Select-Object -Last 1
                        }
                        "securitysuite" {
                            if ([string]::IsNullOrEmpty($ConnectionResult.EXOAccessToken) -or [string]::IsNullOrEmpty($ConnectionResult.EXOApiEndpoint)) {
                                throw "Missing EXO token or endpoint for SecuritySuite provider. Re-run with -LogIn or check authentication."
                            }
                            $SecuritySuiteProviderParams = @{
                                'M365Environment' = $ScubaConfig.M365Environment
                                'AccessToken' = $ConnectionResult.EXOAccessToken
                                'ApiEndpoint' = $ConnectionResult.EXOApiEndpoint
                            }
                            $RetVal = Export-SecuritySuiteProvider @SecuritySuiteProviderParams | Select-Object -Last 1
                        }
                        "powerplatform" {
                            $PPProviderParams = @{
                                'M365Environment' = $ScubaConfig.M365Environment
                                'AccessToken'     = $ConnectionResult.PPAccessToken
                                'BaseUrl'         = $ConnectionResult.PPBaseUrl
                            }
                            $RetVal = Export-PowerPlatformProvider @PPProviderParams | Select-Object -Last 1
                        }
                        "sharepoint" {
                            $SPOProviderParams = @{
                                'AccessToken'     = $ConnectionResult.SPOAccessToken
                                'AdminUrl'        = $ConnectionResult.SPOAdminUrl
                            }
                            $RetVal = Export-SharePointProvider @SPOProviderParams | Select-Object -Last 1
                        }
                        "powerbi" {
                            $PBIProviderParams = @{
                                'AccessToken'       = $ConnectionResult.PBIAccessToken
                                'BaseUrl'           = $ConnectionResult.PBIBaseUrl
                                'LicenseFound'      = $ConnectionResult.PBILicenseFound
                            }
                            $RetVal = Export-PowerBIProvider @PBIProviderParams | Select-Object -Last 1
                        }
                        "teams" {
                            if ($ServicePrincipalAuth) {
                                $RetVal = Export-TeamsProvider -CertificateBasedAuth | Select-Object -Last 1
                            }
                            else {
                                $RetVal = Export-TeamsProvider | Select-Object -Last 1
                            }
                        }
                        default {
                            Write-Error -Message "Invalid ProductName argument"
                        }
                    }
                    $ProviderJSON += $RetVal
                    Write-ScubaLog -Message "Provider export succeeded: $BaselineName" -Level "Debug" -Source "ProviderList" -Data @{ Product = $Product }
                }
                catch {
                    Write-Warning "Error with the $($BaselineName) Provider: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                    Write-ScubaLog -Message "Provider export failed: $BaselineName" -Level "Warning" -Source "ProviderList" -Data @{
                        Product = $Product
                        Error   = $_.Exception.Message
                        StackTrace = $_.ScriptStackTrace
                    }
                    $ProdProviderFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above `n`n"
                }
            }

            $ProviderJSON = $ProviderJSON.TrimEnd(",")
            $TimeZone = ""
            $CurrentDate = Get-Date -ErrorAction 'Stop'
            $TimestampZulu = $CurrentDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $GetTimeZone = Get-TimeZone -ErrorAction 'Stop'
            if (($CurrentDate).IsDaylightSavingTime()) {
                $TimeZone = ($GetTimeZone).DaylightName
            }
            else {
                $TimeZone = ($GetTimeZone).StandardName
            }

        $ConfigDetails = @(ConvertTo-Json -Depth 20 $ScubaConfig)
        if(! $ConfigDetails) {
            $ConfigDetails = "{}"
        }

        $BaselineSettingsExport = @"
        {
                "baseline_version": "1",
                "module_version": "$ModuleVersion",
                "date": "$($CurrentDate) $($TimeZone)",
                "timestamp_zulu": "$($TimestampZulu)",
                "report_uuid": "$($Guid)",
                "tenant_details": $($TenantDetails),
                "scuba_config": $($ConfigDetails),
                $ProviderJSON
        }
"@

            # If any of the providers produced JSON data, we check it for invalid JSON and try to repair it if necessary.
            if ($ProviderJSON.Length -gt 0) {
                # Parse the JSON string and repair it if invalid JSON was found.
                $ReturnObject = Repair-ScubaGearJson -JsonInputString $BaselineSettingsExport

                $BaselineSettingsExportFinal = $null
                # If we performed a repair.
                if ($ReturnObject.RepairedJson) {
                    # Make sure ScubaGear references the repaired ScubaResults JSON string.
                    $BaselineSettingsExportFinal = $ReturnObject.JsonString
                    # Save a backup of the invalid JSON file in case the user wants to report it to the ScubaGear dev team.
                    $InvalidJSONLocation = Set-Utf8NoBom -Content $BaselineSettingsExport `
                        -Location $OutFolderPath -FileName "Invalid-$($ScubaConfig.OutProviderFileName).json"
                    Write-Warning "Saved the invalid JSON file to the following location so you can provide it to the ScubaGear team for debugging: $InvalidJSONLocation"
                }
                # Repair was not needed so use the ScubaResults JSON as-is
                else {
                    $BaselineSettingsExportFinal = $BaselineSettingsExport
                }
            }
            # If providers didn't produce any JSON data, there is nothing to repair, so use the ScubaResults JSON as-is
            else {
                $BaselineSettingsExportFinal = $BaselineSettingsExport
            }

            # PowerShell 5 includes the "byte-order mark" (BOM) when it writes UTF-8 files. However, OPA (as of 0.68) appears to not
            # be able to handle the "\/" character sequence if the input json is UTF-8 encoded with the BOM, resulting
            # in the "unable to parse input: yaml" error message. As such, we need to save the provider output without
            # the BOM
            $ActualSavedLocation = Set-Utf8NoBom -Content $BaselineSettingsExportFinal `
                -Location $OutFolderPath -FileName "$($ScubaConfig.OutProviderFileName).json"
            Write-Debug $ActualSavedLocation

            $ProdProviderFailed
        }
        catch {
            Write-ScubaLog -Message "Fatal error in provider functions" -Level "Error" -Source "ProviderList" -Data @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }
            $InvokeProviderListErrorMessage = "Fatal Error involving the Provider functions. `
            Ending ScubaGear execution. Error: $($_.Exception.Message)`"
            `n$($_.ScriptStackTrace)"
            throw $InvokeProviderListErrorMessage
        }
    }
}

function Invoke-RunRego {
    <#
    .Description
    This function runs the RunRego module.
    Which runs the various rego files against the
    ProviderSettings.json using the specified OPA executable
    Output will be stored as a TestResults.json in the OutPath Folder
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $ScubaConfig,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ParentPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OutFolderPath
    )
    process {
        try {
            $ProdRegoFailed = @()
            $TestResults = @()
            $N = 0
            $Len = $ScubaConfig.ProductNames.Length
            foreach ($Product in $ScubaConfig.ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N * 100 / $Len

                $Status = "Running the $($BaselineName) Rego Verification; $($N) of $($Len) Rego verifications completed"
                $ProgressParams = @{
                    'Activity' = "Running the rego for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams
                $InputFile = Join-Path -Path $OutFolderPath "$($ScubaConfig.OutProviderFileName).json" -ErrorAction 'Stop'
                $RegoFile = Join-Path -Path $ParentPath -ChildPath "Rego" -ErrorAction 'Stop'
                $RegoFile = Join-Path -Path $RegoFile -ChildPath "$($BaselineName)Config.rego" -ErrorAction 'Stop'
                $resolvedOPAPath = if ($ScubaConfig.OPAPath) { $ScubaConfig.OPAPath } else { [ScubaConfig]::ScubaDefault('DefaultOPAPath') }
                $params = @{
                    'InputFile' = $InputFile;
                    'RegoFile' = $RegoFile;
                    'PackageName' = $Product;
                    'OPAPath' = $resolvedOPAPath
                }
                Write-ScubaLog -Message "Starting Rego evaluation: $BaselineName" -Level "Debug" -Source "RunRego" -Data @{
                    Product     = $Product
                    OPAPath     = $resolvedOPAPath
                    InputFile   = $InputFile
                    RegoFile    = $RegoFile
                    InputExists = (Test-Path $InputFile)
                    RegoExists  = (Test-Path $RegoFile)
                }
                try {
                    $RetVal = Invoke-Rego @params
                    $TestResults += $RetVal
                    Write-ScubaLog -Message "Rego evaluation succeeded: $BaselineName" -Level "Debug" -Source "RunRego" -Data @{ Product = $Product }
                }
                catch {
                    Write-Warning "Error with the $($BaselineName) Rego invocation: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                    Write-ScubaLog -Message "Rego evaluation failed: $BaselineName" -Level "Warning" -Source "RunRego" -Data @{
                        Product   = $Product
                        OPAPath   = $resolvedOPAPath
                        InputFile = $InputFile
                        RegoFile  = $RegoFile
                        Error     = $_.Exception.Message
                        StackTrace = $_.ScriptStackTrace
                    }
                    $ProdRegoFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above"
                }
            }

            $TestResultsJson = $TestResults | ConvertTo-Json -Depth 5 -ErrorAction 'Stop'
            $FileName = Join-Path -Path $OutFolderPath "$($ScubaConfig.OutRegoFileName).json" -ErrorAction 'Stop'
            $TestResultsJson | Set-Content -Path $FileName -Encoding (Get-FileEncoding) -ErrorAction 'Stop'

            $ProdRegoFailed
        }
        catch {
            Write-ScubaLog -Message "Fatal error in OPA output function" -Level "Error" -Source "RunRego" -Data @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }
            $InvokeRegoErrorMessage = "Fatal Error involving the OPA output function. `
            Ending ScubaGear execution. Error: $($_.Exception.Message)`"
            `n$($_.ScriptStackTrace)"
            throw $InvokeRegoErrorMessage
        }
    }
}

function Pluralize {
    <#
    .Description
    This function whether the singular or plural version of the noun
    is needed and returns the appropriate version.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SingularNoun,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PluralNoun,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Count
    )
    process {
        if ($Count -gt 1) {
            $PluralNoun
        }
        else {
            $SingularNoun
        }
    }
}

function Format-PlainText {
    <#
    .Description
    This function sanitizes a given string so that it will render properly in Excel (e.g., remove HTML tags).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RawString
    )
    process {
        $CleanString = $RawString
        # Multi-line strings (e.g., the requirment string for MS.EXO.16.1v1) need to be merged into a single
        # line, otherwise the single control will be split into multiple rows in the CSV output
        $CleanString = $CleanString.Replace("`n", " ")
        # The "View all CA policies" link needs to be removed from the spreadsheet as what it links to
        # does not exist in the spreadsheet
        $CleanString = $CleanString.Replace("<a href='#caps'>View all CA policies</a>.", "")
        # Remove HTML tags that won't render properly in the spreadsheet and whose removal won't affect the
        # overall meaning of the string
        $CleanString = $CleanString.Replace("<br/>", " ")
        $CleanString = $CleanString.Replace("<b>", "")
        $CleanString = $CleanString.Replace("</b>", "")

        # Strip out HTML comments
        $CleanString = $CleanString -replace '(.*)(<!--)(.*)(-->)(.*)', '$1$5'
        # The following regex looks for a string with an anchor tag. If it finds an anchor tag, it reformats
        # the string so that the anchor is removed. For example:
        # 'See <a href="https://example.com" target="_blank">this example</a> for more details.'
        # becomes
        # 'See this example, https://example.com for more details.'
        # In-depth interpretation:
        # Group 1: '(.*)' Matches any number of characters before the opening anchor tag
        # Group 2: '<a href="' Matches the opening anchor tag, up to and including the opening quote of the href
        # Group 3: '([\w#./=&?%\-+:;$@,]+)' Matches the href string
        # Group 4: '(".*>)' Matches the last half of the opening anchor tag
        # Group 5: '(.*)' Matches the anchor inner html, i.e., the link's display text
        # Group 6: '(</a>)' Matches the closing anchor tag
        # Group 7: '(.*)' Matches any number of characters after the closing anchor tag
        $CleanString = $CleanString -replace '(.*)(<a href=")([\w#./=&?%\-+:;$@,]+)(".*>)(.*)(</a>)(.*)', '$1$5, $3$7'
        $CleanString
    }
}

function Get-FullOutJsonName {
    <#
    .Description
    This function determines the full file name of the SCuBA results file.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate
    )
    process {
        # Truncate the UUID at the end of the ScubaResults JSON file by the parameter value.
        # This is is to possibly prevent Windows maximum path length errors that may occur when moving files
        # with a large number of characters
        $TruncatedGuid = $Guid.Substring(0, $Guid.Length - $NumberOfUUIDCharactersToTruncate)

        # If the UUID still exists after truncation
        if ($TruncatedGuid.Length -gt 0) {
            $ScubaResultsFileName = "$($OutJsonFileName)_$($TruncatedGuid).json"
        }
        else {
            # Otherwise omit adding it to the resulting file name
            $ScubaResultsFileName = "$($OutJsonFileName).json"
        }

        $ScubaResultsFileName
    }
}

function ConvertTo-ResultsCsv {
    <#
    .Description
    This function converts the controls inside the Results section of the json output to a csv.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FullScubaResultsName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName
    )
    process {
        try {
            $ScubaResultsPath = Join-Path $OutFolderPath -ChildPath $FullScubaResultsName

            if (Test-Path $ScubaResultsPath -PathType Leaf) {
                # The ScubaResults file exists, no need to look for the individual json files
                $ScubaResults = Get-Content -Encoding UTF8 (Get-ChildItem $ScubaResultsPath).FullName | ConvertFrom-Json
            }
            else {
                # The ScubaResults file does not exists, so we need to look inside the IndividualReports
                # folder for the json file specific to each product
                $ScubaResults = @{"Results" = [PSCustomObject]@{}}
                $IndividualReportPath = Join-Path -Path $OutFolderPath $IndividualReportFolderName -ErrorAction 'Stop'
                foreach ($Product in $ProductNames) {
                    $BaselineName = $ArgToProd[$Product]
                    $FileName = Join-Path $IndividualReportPath "$($BaselineName)Report.json"
                    $IndividualResults = Get-Content -Encoding UTF8 $FileName | ConvertFrom-Json
                    $ScubaResults.Results | Add-Member -NotePropertyName $BaselineName `
                        -NotePropertyValue $IndividualResults.Results
                }
            }
            $ActionPlanCsv = @()
            $ScubaResultsCsv = @()
            foreach ($Product in $ScubaResults.Results.PSObject.Properties) {
                foreach ($Group in $Product.Value) {
                    foreach ($Control in $Group.Controls) {
                        $Control.Requirement = Format-PlainText -RawString $Control.Requirement
                        $Control.Details = Format-PlainText -RawString $Control.Details
                        $ScubaResultsCsv += $Control
                        if ($Control.Result -eq "Fail") {
                            # Add blank fields where users can document reasons for failures and timelines
                            # for remediation if they so choose
                            # The space " " instead of empty string makes it so that output from the cells to the
                            # left won't automatically overlap into the space for these columns in Excel
                            $Reason = " "
                            $RemediationDate = " "
                            $Justification = " "
                            $Control | Add-Member -NotePropertyName "Non-Compliance Reason" -NotePropertyValue $Reason
                            $Control | Add-Member -NotePropertyName "Remediation Completion Date" `
                            -NotePropertyValue $RemediationDate
                            $Control | Add-Member -NotePropertyName "Justification" -NotePropertyValue $Justification
                            $ActionPlanCsv += $Control
                        }
                    }
                }
            }
            $ResultsCsvFileName = Join-Path -Path $OutFolderPath "$OutCsvFileName.csv"
            $PlanCsvFileName = Join-Path -Path $OutFolderPath "$OutActionPlanFileName.csv"
            $Encoding = Get-FileEncoding
            $ScubaResultsCsv | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $ResultsCsvFileName -Encoding $Encoding
            if ($ActionPlanCsv.Length -eq 0) {
                # If no tests failed, add the column names to ensure a file is still output
                $Headers = $ScubaResultsCsv[0].psobject.Properties.Name -Join '","'
                $Headers = "`"$Headers`""
                $Headers += '"Non-Compliance Reason","Remediation Completion Date","Justification"'
                $Headers | Set-Content -Path $PlanCsvFileName -Encoding $Encoding
            }
            else {
                $ActionPlanCsv | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $PlanCsvFileName -Encoding $Encoding
            }
        }
        catch {
            Write-ScubaLog -Message "Error creating CSV output file" -Level "Warning" -Source "CreateCsv" -Data @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }
            Write-Warning "Error creating CSV output file: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        }
    }
}

function Merge-JsonOutput {
    <#
    .Description
    This function packages all the json output created into a single json file.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $TenantDetails,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FullScubaResultsName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

        [Parameter(Mandatory=$false)]
        [boolean]
        $SilenceBODWarnings
    )
    process {
        try {
            # Files to delete at the end if no errors are encountered
            $DeletionList = @()

            # Load the raw provider output
            $SettingsExportPath = Join-Path $OutFolderPath -ChildPath "$($OutProviderFileName).json"
            $DeletionList += $SettingsExportPath
            $SettingsExport =  Get-Content -Encoding UTF8 $SettingsExportPath -Raw
            $SettingsExportObject = $(ConvertFrom-Json $SettingsExport)
            $TimestampZulu = $SettingsExportObject.timestamp_zulu

            # Get a list and abbreviation mapping of the products assessed
            $FullNames = @()
            $ProductAbbreviationMapping = @{}
            foreach ($ProductName in $ProductNames) {
                $BaselineName = $ArgToProd[$ProductName]
                $FullNames += $ProdToFullName[$BaselineName]
                $ProductAbbreviationMapping[$ProdToFullName[$BaselineName]] = $BaselineName
            }

            $Results = [pscustomobject]@{}
            $Summary = [pscustomobject]@{}
            $AnnotatedFailedPolicies = [pscustomobject]@{}
            # Extract the metadata
            $MetaData = [pscustomobject]@{
                "TenantId" = $TenantDetails.TenantId;
                "DisplayName" = $TenantDetails.DisplayName;
                "DomainName" = $TenantDetails.DomainName;
                "ProductSuite" = "Microsoft 365";
                "ProductsAssessed" = $FullNames;
                "ProductAbbreviationMapping" = $ProductAbbreviationMapping
                "Tool" = "ScubaGear";
                "ToolVersion" = $ModuleVersion;
                "TimestampZulu" = $TimestampZulu;
                "ReportUUID" = $Guid;
            }


            # Aggregate the report results and summaries
            $IndividualReportPath = Join-Path -Path $OutFolderPath $IndividualReportFolderName -ErrorAction 'Stop'
            $FailsNotAnnotated = @()
            foreach ($Product in $ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $FileName = Join-Path $IndividualReportPath "$($BaselineName)Report.json"
                $DeletionList += $FileName
                $IndividualResults = Get-Content -Encoding UTF8 $FileName | ConvertFrom-Json

                $Results | Add-Member -NotePropertyName $BaselineName `
                    -NotePropertyValue $IndividualResults.Results

                # The date is listed under the metadata, no need to include it in the summary as well
                $IndividualResults.ReportSummary.PSObject.Properties.Remove('Date')
                $Summary | Add-Member -NotePropertyName $BaselineName `
                    -NotePropertyValue $IndividualResults.ReportSummary

                # Collect the annotated failed policies into a single object
                foreach ($Annotation in $IndividualResults.ReportSummary.AnnotatedFailedPolicies.PSObject.Properties) {
                    if ($null -eq $Annotation.Value.Comment) {
                        $FailsNotAnnotated += $Annotation.Name
                    }
                    $AnnotatedFailedPolicies | Add-Member -NotePropertyName $Annotation.Name `
                        -NotePropertyValue $Annotation.Value
                }
                $IndividualResults.ReportSummary.PSObject.Properties.Remove('AnnotatedFailedPolicies')
            }
            if (-not $SilenceBODWarnings -and $FailsNotAnnotated.Length -gt 0) {
                $Warning = "$($FailsNotAnnotated.Length) controls are failing and are not documented in the config file: "
                $Warning += $FailsNotAnnotated -Join ", "
                $Warning += ". See https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/configuration.md#annotate-policies for more details."
                Write-Warning $Warning
            }
            foreach ($Product in $Results.PSObject.Properties) {
                foreach ($Group in $Product.Value) {
                    foreach ($Control in $Group.Controls) {
                        $Control.Requirement = Format-PlainText -RawString $Control.Requirement
                        $Control.Details = Format-PlainText -RawString $Control.Details
                    }
                }
            }

            # Convert the output a json string
            $MetaData = ConvertTo-Json $MetaData -Depth 3
            $Results = ConvertTo-Json $Results -Depth 5
            $Summary = ConvertTo-Json $Summary -Depth 3
            $AnnotatedFailedPolicies = ConvertTo-Json $AnnotatedFailedPolicies -Depth 3
            $ReportJson = @"
{
    "MetaData": $MetaData,
    "Summary": $Summary,
    "AnnotatedFailedPolicies": $AnnotatedFailedPolicies,
    "Results": $Results,
    "Raw": $SettingsExport
}
"@

            # ConvertTo-Json for some reason converts the <, >, and ' characters into unicode escape sequences.
            # Convert those back to ASCII.
            $ReportJson = $ReportJson.replace("\u003c", "<")
            $ReportJson = $ReportJson.replace("\u003e", ">")
            $ReportJson = $ReportJson.replace("\u0027", "'")

            $ScubaResultsPath = Join-Path $OutFolderPath -ChildPath $FullScubaResultsName -ErrorAction 'Stop'
            $ReportJson | Set-Content -Path $ScubaResultsPath -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'

            # Delete the now redundant files
            foreach ($File in $DeletionList) {
                Remove-Item $File
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "GetContentWriterPathTooLongError,Microsoft.PowerShell.Commands.SetContentCommand") {
                Write-ScubaLog -Message "Path too long error in JSON merge" -Level "Error" -Source "MergeJson" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                    ErrorId = $_.FullyQualifiedErrorId
                }
                $MAX_WINDOWS_PATH_LEN = 256
                $PathLengthErrorMessage = "ScubaGear was likely executed in a location where the maximum file path length is greater than the allowable Windows file system limit `
                Please execute ScubaGear in a directory where for Windows file path limit is less than $($MAX_WINDOWS_PATH_LEN).`
                Another option is to change the -NumberOfUUIDCharactersToTruncate, -OutJSONFileName, or -OutFolderName parameters to achieve an acceptable file path length `
                See the Invoke-SCuBA parameters documentation for more details. `
                Error: $($_.Exception.Message) `
                Stacktrace: $($_.ScriptStackTrace)"
                throw $PathLengthErrorMessage
            }
            else {
                Write-ScubaLog -Message "Fatal error in JSON merge" -Level "Error" -Source "MergeJson" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                $MergeJsonErrorMessage = "Fatal Error involving the Json reports aggregation. `
                Ending ScubaGear execution. Error: $($_.Exception.Message) `
                Stacktrace: $($_.ScriptStackTrace)"
                throw $MergeJsonErrorMessage
            }
        }
    }
}

function Invoke-ReportCreation {
    <#
    .Description
    This function runs the CreateReport Module
    which creates an HTML report using the TestResults.json.
    Output will be stored as various HTML files in the OutPath Folder.
    The report Home page will be named BaselineReports.html
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $ScubaConfig,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $TenantDetails,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode
    )
    process {
        try {
            $N = 0
            $Len = $ScubaConfig.ProductNames.Length
            $Fragment = @()
            $IndividualReportPath = Join-Path -Path $OutFolderPath -ChildPath $IndividualReportFolderName
            New-Item -Path $IndividualReportPath -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

            $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport" -ErrorAction 'Stop'
            $Images = Join-Path -Path $ReporterPath -ChildPath "images" -ErrorAction 'Stop'
            Copy-Item -Path $Images -Destination $IndividualReportPath -Force -Recurse -ErrorAction 'Stop'

            $SecureBaselines =  Import-SecureBaseline -ProductNames $ScubaConfig.ProductNames

            foreach ($Product in $ScubaConfig.ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N*100/$Len
                $Status = "Running the $($BaselineName) Report creation; $($N) of $($Len) Baselines Reports created";
                $ProgressParams = @{
                    'Activity' = "Creating the reports for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams

                $FullName = $ProdToFullName[$BaselineName]

                $CreateReportParams = @{
                    'BaselineName' = $BaselineName;
                    'FullName' = $FullName;
                    'IndividualReportPath' = $IndividualReportPath;
                    'OutPath' = $OutFolderPath;
                    'OutProviderFileName' = $ScubaConfig.OutProviderFileName;
                    'OutRegoFileName' = $ScubaConfig.OutRegoFileName;
                    'DarkMode' = $DarkMode;
                    'SecureBaselines' = $SecureBaselines
                }

                $Report = New-Report @CreateReportParams
                Write-ScubaLog -Message "Report created: $BaselineName" -Level "Info" -Source "ReportCreation" -Data @{
                    Product  = $Product
                    Passes   = $Report.Passes
                    Failures = $Report.Failures
                    Warnings = $Report.Warnings
                    Manual   = $Report.Manual
                    Omits    = $Report.Omits
                    Errors   = $Report.Errors
                }
                $LinkPath = "$($IndividualReportFolderName)/$($BaselineName)Report.html"
                $LinkClassName = '"individual_reports"' # uses no escape characters
                $Link = "<a class=$($LinkClassName) href='$($LinkPath)'>$($FullName)</a>"
                $PassesSummary = "<div class='summary'></div>"
                $WarningsSummary = "<div class='summary'></div>"
                $FailuresSummary = "<div class='summary'></div>"
                $BaselineURL = "<a href= `"https://github.com/cisagov/ScubaGear/blob/v$($ModuleVersion)/baselines`" target=`"_blank`"><h3 style=`"width: 100px;`">Baseline Documents</h3></a>"
                $ManualSummary = "<div class='summary'></div>"
                $OmitSummary = "<div class='summary'></div>"
                $IncorrectResultSummary = "<div class='summary'></div>"
                $ErrorSummary = ""

                if ($Report.Passes -gt 0) {
                    $Noun = Pluralize -SingularNoun "pass" -PluralNoun "passes" -Count $Report.Passes
                    $PassesSummary = "<div class='summary pass'>$($Report.Passes) $($Noun)</div>"
                }

                if ($Report.Warnings -gt 0) {
                    $Noun = Pluralize -SingularNoun "warning" -PluralNoun "warnings" -Count $Report.Warnings
                    $WarningsSummary = "<div class='summary warning'>$($Report.Warnings) $($Noun)</div>"
                }

                if ($Report.Failures -gt 0) {
                    $Noun = Pluralize -SingularNoun "failure" -PluralNoun "failures" -Count $Report.Failures
                    $FailuresSummary = "<div class='summary failure'>$($Report.Failures) $($Noun)</div>"
                }

                if ($Report.Manual -gt 0) {
                    $Noun = Pluralize -SingularNoun "check" -PluralNoun "checks" -Count $Report.Manual
                    $ManualSummary = "<div class='summary manual'>$($Report.Manual) manual $($Noun)</div>"
                }

                if ($Report.Omits -gt 0) {
                    $OmitSummary = "<div class='summary manual'>$($Report.Omits) omitted</div>"
                }

                if ($Report.IncorrectResults -gt 0) {
                    $Noun = Pluralize -SingularNoun "incorrect result" -PluralNoun "incorrect results" -Count $Report.IncorrectResults
                    $IncorrectResultSummary = "<div class='summary incorrect'>$($Report.IncorrectResults) $Noun</div>"
                }

                if ($Report.Errors -gt 0) {
                    $Noun = Pluralize -SingularNoun "error" -PluralNoun "errors" -Count $Report.Errors
                    $ErrorSummary = "<div class='summary error'>$($Report.Errors) $($Noun)</div>"
                }

                $Fragment += [pscustomobject]@{
                "Baseline Conformance Reports" = $Link;
                "Details" = "$PassesSummary $WarningsSummary $FailuresSummary $ManualSummary $OmitSummary $IncorrectResultSummary $ErrorSummary"
                }
            }
            $TenantMetaData += [pscustomobject]@{
                "Tenant Display Name" = $TenantDetails.DisplayName;
                "Tenant Domain Name" = $TenantDetails.DomainName
                "Tenant ID" = $TenantDetails.TenantId;
                "Report Date" = $Report.Date;
            }
            $TenantMetaData = $TenantMetaData | ConvertTo-Html -Fragment -ErrorAction 'Stop'
            $TenantMetaData = $TenantMetaData -replace '^(.*?)<table>','<table class ="tenantdata" style = "text-align:center;">'
            $Fragment = $Fragment | ConvertTo-Html -Fragment -ErrorAction 'Stop'

            $ProviderJSONFilePath = Join-Path -Path $OutFolderPath -ChildPath "$($ScubaConfig.OutProviderFileName).json" -Resolve
            $ReportUuid = $(Get-Utf8NoBom -FilePath $ProviderJSONFilePath | ConvertFrom-Json).report_uuid

            $ReportHtmlPath = Join-Path -Path $ReporterPath -ChildPath "ParentReport" -ErrorAction 'Stop'
            $JsonScriptTags = @(
                "<script type='application/json' id='dark-mode-flag'> $($DarkMode.ToString().ToLower()) </script>"
            ) -join "`n"
            $ReportHTML = (Get-Content $(Join-Path -Path $ReportHtmlPath -ChildPath "ParentReport.html") -ErrorAction 'Stop') -Join "`n"
            $ReportHTML = $ReportHTML.Replace("{TENANT_DETAILS}", $TenantMetaData)
            $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragment)
            $ReportHTML = $ReportHTML.Replace("{REPORT_UUID}", $ReportUuid)
            $ReportHTML = $ReportHTML.Replace("{MODULE_VERSION}", "v$ModuleVersion")
            $ReportHTML = $ReportHTML.Replace("{BASELINE_URL}", $BaselineURL)

            # Inject CSS into parent HTML report template
            $CssPath = Join-Path -Path $ReporterPath -ChildPath "styles" -ErrorAction "Stop"
            $MainCSS = Get-Content (Join-Path -Path $CssPath -ChildPath "Main.css") -Raw
            $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>`n $($MainCSS) `n</style>")

            $ParentCSS = Get-Content (Join-Path -Path $CssPath -ChildPath "ParentReportStyle.css") -Raw
            $ReportHTML = $ReportHTML.Replace("{PARENT_CSS}", "<style>`n $($ParentCSS) `n</style>")
            $ReportHTML = $ReportHTML.Replace("{JSON_SCRIPT_TAGS}", $JsonScriptTags)

            $ScriptsPath = Join-Path -Path $ReporterPath -ChildPath "scripts" -ErrorAction "Stop"
            $ParentReportJS = Get-Content (Join-Path -Path $ScriptsPath -ChildPath "ParentReport.js") -Raw
            $UtilsJS = Get-Content (Join-Path -Path $ScriptsPath -ChildPath "Utils.js") -Raw

            $JSFiles = @(
                $ParentReportJS
                $UtilsJS
            ) -join "`n"

            $ReportHTML = $ReportHTML.Replace("{JS_FILES}", "<script>`n $($JSFiles) `n</script>")
            Add-Type -AssemblyName System.Web -ErrorAction 'Stop'
            $ReportFileName = Join-Path -Path $OutFolderPath "$($ScubaConfig.OutReportName).html" -ErrorAction 'Stop'
            [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $ReportFileName -ErrorAction 'Stop'

            if (-Not $Quiet) {
                Invoke-Item $ReportFileName
            }
        }
        catch {
            Write-ScubaLog -Message "Fatal error in report creation" -Level "Error" -Source "CreateReport" -Data @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }
            $InvokeReportErrorMessage = "Fatal Error involving the Report Creation. `
            Ending ScubaGear execution. Error: $($_.Exception.Message)`"
            `n$($_.ScriptStackTrace)"
            throw $InvokeReportErrorMessage
        }
    }
}

function Get-EXOTenantDetailFromConnection {
    <#
    .Description
    Gets tenant details through EXO Admin API using existing Defender/EXO connection context.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ConnectionResult
    )

    $EXORestHelperPath = Join-Path -Path $PSScriptRoot -ChildPath "Providers/ProviderHelpers/EXORestHelper.psm1"
    Import-Module -Name $EXORestHelperPath -Function Invoke-EXORestMethod -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($ConnectionResult.EXOAccessToken) -or [string]::IsNullOrWhiteSpace($ConnectionResult.EXOApiEndpoint)) {
        throw "Missing EXO token or endpoint in ConnectionResult."
    }

    $OrgConfigResponse = Invoke-EXORestMethod `
        -CmdletName "Get-OrganizationConfig" `
        -ApiEndpoint $ConnectionResult.EXOApiEndpoint `
        -AccessToken $ConnectionResult.EXOAccessToken

    $OrgConfig = if ($OrgConfigResponse -is [System.Array]) { $OrgConfigResponse | Select-Object -First 1 } else { $OrgConfigResponse }
    if (-not $OrgConfig) {
        throw "Get-OrganizationConfig returned no data."
    }

    $TenantId = "Error retrieving Tenant ID"
    $TenantIdMatch = [regex]::Match($ConnectionResult.EXOApiEndpoint, '/adminapi/(?:beta|v1\.0)/([^/]+)/InvokeCommand')
    if ($TenantIdMatch.Success) {
        $TenantId = $TenantIdMatch.Groups[1].Value
    }

    $DomainName = if ($OrgConfig.Name) { [string]$OrgConfig.Name } else { "Error retrieving Domain name" }
    $DisplayName = if ($OrgConfig.DisplayName) { [string]$OrgConfig.DisplayName } else { $DomainName }

    $TenantInfo = @{
        "DisplayName" = $DisplayName;
        "DomainName" = $DomainName;
        "TenantId" = $TenantId;
        "EXOAdditionalData" = "Retrieved via EXO REST Admin API";
    }

    ConvertTo-Json @($TenantInfo) -Depth 4
}

function Get-TenantDetail {
    <#
    .Description
    This function gets the details of the M365 Tenant using
    the various M365 PowerShell modules
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [hashtable]
        $ConnectionResult
    )

    # organized by best tenant details information
    if ($ProductNames.Contains("aad")) {
        Get-AADTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("sharepoint")) {
        Get-AADTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("powerbi")) {
        Get-AADTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("teams")) {
        Get-TeamsTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("powerplatform")) {
        Get-PowerPlatformTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("exo")) {
        Get-EXOTenantDetail -M365Environment $M365Environment `
            -AccessToken $ConnectionResult.EXOAccessToken `
            -ApiEndpoint $ConnectionResult.EXOApiEndpoint
    }
    elseif ($ProductNames.Contains("securitysuite")) {
        Get-EXOTenantDetail -M365Environment $M365Environment `
            -AccessToken $ConnectionResult.EXOAccessToken `
            -ApiEndpoint $ConnectionResult.EXOApiEndpoint
    }
    else {
        $TenantInfo = @{
            "DisplayName" = "Orchestrator Error retrieving Display name";
            "DomainName" = "Orchestrator Error retrieving Domain name";
            "TenantId" = "Orchestrator Error retrieving Tenant ID";
            "AdditionalData" = "Orchestrator Error retrieving additional data";
        }
        $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 3
        $TenantInfo
    }
}

function Invoke-Connection {
    <#
    .Description
    This function uses the Connection.psm1 module
    which uses the various PowerShell modules to establish
    a connection to an M365 Tenant associated with provided
    credentials
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $ScubaConfig
    )

    $ConnectTenantParams = @{
        'ProductNames' = $ScubaConfig.ProductNames;
        'M365Environment' = $ScubaConfig.M365Environment
    }

    if ($ScubaConfig.AppID) {
        $ServicePrincipalParams = Get-ServicePrincipalParams -ScubaConfig $ScubaConfig
        $ConnectTenantParams += @{ServicePrincipalParams = $ServicePrincipalParams;}
    }

    $ConnectionResult = @{
        ProdAuthFailed = @()
        EXOAccessToken = $null
        EXOApiEndpoint = $null
    }

    if ($ScubaConfig.LogIn) {
        $ConnectionResult = Connect-Tenant @ConnectTenantParams
    }

    $ConnectionResult
}

function Compare-ProductList {
    <#
    .Description
    Compares two ProductNames Lists and returns the Diff between them
    Used to compare a failed execution list with the original list
    .Functionality
    Internal
    #>
    param(

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductsFailed,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ExceptionMessage
    )

    $Difference = Compare-Object $ProductNames -DifferenceObject $ProductsFailed -PassThru
    if (-not $Difference) {
        # Log critical failure before aborting - use the provided exception message for accuracy
        Write-ScubaLog -Message "CRITICAL: $ExceptionMessage; aborting execution" -Level "Error" -Source "CompareProductList" -Data @{
            RequestedProducts = ($ProductNames -join ', ')
            FailedProducts = ($ProductsFailed -join ', ')
            ExceptionMessage = $ExceptionMessage
        }
        throw "$($ExceptionMessage); aborting ScubaGear execution"
    }
    else {
        $Difference
    }
}

function Import-Resources {
    <#
    .Description
    This function imports all of the various helper Provider,
    Rego, and Reporter modules to the runtime
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param()
    try {
        $ProvidersPath = Join-Path -Path $PSScriptRoot `
        -ChildPath "Providers" `
        -Resolve `
        -ErrorAction 'Stop'
        $ProviderResources = Get-ChildItem $ProvidersPath -Recurse | Where-Object { $_.Name -like 'Export*.psm1' }
        if (!$ProviderResources)
        {
            throw "Provider files were not found, aborting this run"
        }

        foreach ($Provider in $ProviderResources.Name) {
            $ProvidersPath = Join-Path -Path $PSScriptRoot -ChildPath "Providers" -ErrorAction 'Stop'
            $ModulePath = Join-Path -Path $ProvidersPath -ChildPath $Provider -ErrorAction 'Stop'
            Import-Module $ModulePath
        }

        @('Connection', 'RunRego', 'CreateReport', 'ScubaConfig', 'Support', 'Utility') | ForEach-Object {
            $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath $_ -ErrorAction 'Stop'
            Write-Debug "Importing $_ module $ModulePath"
            Import-Module -Name $ModulePath
        }

        # Import ScubaLogging explicitly (not part of Utility folder import)
        $ScubaLoggingPath = Join-Path -Path $PSScriptRoot -ChildPath 'Utility\ScubaLogging.psm1' -ErrorAction 'Stop'
        Import-Module -Name $ScubaLoggingPath -Force
    }
    catch {
        Write-ScubaLog -Message "Fatal error importing PowerShell modules" -Level "Error" -Source "ImportResources" -Data @{
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
        $ImportResourcesErrorMessage = "Fatal Error involving importing PowerShell modules. `
            Ending ScubaGear execution. Error: $($_.Exception.Message) `
            `n$($_.ScriptStackTrace)"
            throw $ImportResourcesErrorMessage
    }
}

function Remove-Resources {
    <#
    .Description
    This function cleans up all of the various imported modules
    Mostly meant for dev work
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    $Providers = @("ExportPowerPlatform", "ExportEXOProvider", "ExportAADProvider",
    "ExportSecuritySuiteProvider", "ExportTeamsProvider", "ExportSharePointProvider", "ExportPowerBIProvider")
    foreach ($Provider in $Providers) {
        Remove-Module $Provider -ErrorAction "SilentlyContinue"
    }

    Remove-Module "ScubaConfig" -ErrorAction "SilentlyContinue"
    Remove-Module "RunRego" -ErrorAction "SilentlyContinue"
    Remove-Module "CreateReport" -ErrorAction "SilentlyContinue"
    Remove-Module "Connection" -ErrorAction "SilentlyContinue"
    Remove-Module "ScubaLogging" -ErrorAction "SilentlyContinue"
}

function Invoke-SCuBACached {
    <#
    .SYNOPSIS
    "ScubaCached" mode executes SCuBAGear against a local provider JSON file or ScubaResults JSON file instead of downloading the configurations.
    .Description
    The term "cached" means that ScubaGear refers to a local cached copy of the tenant settings, which is the JSON file.
    This mode bypasses authenticating to M365 to download the configurations. Everything executes locally.
    Instead the mode takes the configurations in the local JSON file and sends them through the Rego and create HTML report workflows.
    This mode is used by:
    1) Developers to test their Rego code with various simulated tenant configurations by modifying the configurations in the local JSON file.
    2) Users to create a report if ScubaGear crashed but still produced a provider JSON file.
    3) ScubaGear's automated functional tests use this mode to test many different simulated tenant configuration scenarios without actually modifying the tenant.
    ScubaCached mode behaves using the following rules and precedence which describe its execution:
    1) It looks for files in the -OutPath folder.
    2) It looks for a provider export file with the name "ProviderSettingsExport.json" or if -OutProviderFileName was passed it will look for a .json file with that name.
    3) If the provider export exists, ScubaCached will pull the configuration settings from that file and then send them to the Rego and report creation modules.
    4) If a provider file does not exist, ScubaCached will look for a ScubaResults*.json file. If it finds one it will pull the configuration settings from that file and then send them to the Rego.
    5) If -KeepIndividualJSON is NOT passed, ScubaCached will create a new ScubaResults file containing the output from the Rego evaluations and the tenant configurations.
    6) If -KeepIndividualJSON is passed, ScubaCached does NOT create a ScubaResults file but it still creates a new HTML report.
    Based on this execution flow, ScubaCached expects either a provider settings JSON file or a ScubaResults JSON file to be present in -OutPath.
    Ideally you should have only one of those two files in -OutPath but if you have both, ScubaCached will use the provider settings file and ignore the ScubaResults file.
    <#
    .Parameter ExportProvider
    This parameter will when set to $true export the provider and act like Invoke-Scuba.
    When set to $false will instead omit authentication plus pulling the provider and will
    instead look in OutPath and run just the Rego verification and Report creation.
    .Parameter ProductNames
    A list of one or more M365 shortened product names that the tool will assess when it is executed. Acceptable product name values are listed below.
    To assess Azure Active Directory you would enter the value aad.
    To assess Exchange Online you would enter exo and so forth.
    - Azure Active Directory: aad
    - Defender for Office 365: defender
    - Exchange Online: exo
    - MS Power Platform: powerplatform
    - SharePoint Online: sharepoint
    - MS Teams: teams.
    Use '*' to run all baselines.
    .Parameter M365Environment
    This parameter is used to authenticate to the different commercial/government environments.
    Valid values include "commercial", "gcc", "gcchigh", or "dod".
    For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    For M365 Government community cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    For M365 Government community cloud High tenants enter the value **"gcchigh"**.
    For M365 Department of Defense tenants enter the value **"dod"**.
    Default is 'commercial'.
    .Parameter OPAPath
    The folder location of the OPA Rego executable file.
    The OPA Rego executable embedded with this project is located in the project's root folder.
    If you want to execute the tool using a version of OPA Rego located in another folder,
    then customize the variable value with the full path to the alternative OPA Rego exe file.
    .Parameter LogIn
    A `$true` or `$false` variable that if set to `$true`
    will prompt you to provide credentials if you want to establish a connection
    to the specified M365 products in the **$ProductNames** variable.
    For most use cases for cached results, leave this variable to be `$false`.
    Authentication is skipped by default. If you want to run verification with authentication
    in the current PowerShell session, set this variable to `$true` to establish a connection.
    Default is $false.
    .Parameter Version
    Will output the current ScubaGear version to the terminal without running this cmdlet.
    .Parameter AppID
    The application ID of the service principal that's used during certificate based
    authentication. A valid value is the GUID of the application ID (service principal).
    .Parameter CertificateThumbprint
    The thumbprint value specifies the certificate that's used for certificate base authentication.
    The underlying PowerShell modules retrieve the certificate from the user's certificate store.
    As such, a copy of the certificate must be located there.
    .Parameter Organization
    Specify the organization that's used in certificate based authentication.
    Use the tenant's tenantname.onmicrosoft.com domain for the parameter value.
    .Parameter OutPath
    The folder path where both the output JSON and the HTML report will be created.
    The folder will be created if it does not exist. Defaults to current directory.
    .Parameter OutFolderName
    The name of the folder in OutPath where both the output JSON and the HTML report will be created.
    Defaults to "M365BaselineConformance". The client's local timestamp will be appended.
    .Parameter OutProviderFileName
    The name of the Provider output JSON created in the folder created in OutPath.
    Defaults to "ProviderSettingsExport".
    .Parameter OutRegoFileName
    The name of the Rego output JSON and CSV created in the folder created in OutPath.
    Defaults to "TestResults".
    .Parameter OutReportName
    The name of the main html file page created in the folder created in OutPath.
    Defaults to "BaselineReports".
    .Parameter KeepIndividualJSON
    Keeps ScubaGear legacy output where files are not merged into an all in one JSON.
    This parameter is for backwards compatibility for those working with the older ScubaGear output files.
    .Parameter OutJsonFileName
    If KeepIndividualJSON is not set, the name of the consolidated json created in the folder
    created in OutPath. Defaults to "ScubaResults". The report UUID will be appended to this.
    .Parameter OutCsvFileName
    The CSV created in the folder created in OutPath that contains the CSV version of the test results.
    Defaults to "ScubaResults".
    .Parameter OutActionPlanFileName
    The CSV created in the folder created in OutPath that contains a CSV template prepopulated with the failed
    SHALL controls with fields for documenting failure causes and remediation plans. Defaults to "ActionPlan".
    .Parameter DarkMode
    Set switch to enable report dark mode by default.
    .Parameter SilenceBODWarnings
    Do not warn for requirements specific to BOD compliance (e.g., documenting OrgName in the config file).
    .Parameter NumberOfUUIDCharactersToTruncate
    Controls how many characters will be truncated from the report UUID when appended to the end of OutJsonFileName.
    Valid values are 0, 13, 18, 36
    .Example
    Invoke-SCuBACached
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformaance_*.
    .Example
    Invoke-SCuBACached -Version
    This example returns the version of SCuBAGear.
    .Example
    Invoke-SCuBACached -ProductNames aad, defender -OPAPath . -OutPath .
    The example will run the tool against the Azure Active Directory, and Defender security
    baselines.
    .Example
    Invoke-SCuBACached -ProductNames * -M365Environment dod -OPAPath . -OutPath .
    This example will run the tool against all available security baselines with the
    'dod' teams endpoint.
    .Example
    Invoke-SCuBA -ProductNames * -CertificateThumbprint <insert-thumbprint> -AppID <insert-appid> -Organization "tenant.onmicrosoft.com"
    This example will run the tool against all available security baselines while authenticating using a Service Principal with the CertificateThumprint bundle of parameters.
    .Functionality
    Public
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [boolean]
        $ExportProvider = $true,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = [ScubaConfig]::ScubaDefault('DefaultProductNames'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [ValidateNotNullOrEmpty()]
        [string]
        $OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $false,

        [Parameter(ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = [ScubaConfig]::ScubaDefault('DefaultOutPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = [ScubaConfig]::ScubaDefault('DefaultOutProviderFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = [ScubaConfig]::ScubaDefault('DefaultOutRegoFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = [ScubaConfig]::ScubaDefault('DefaultOutReportName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $KeepIndividualJSON,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName = [ScubaConfig]::ScubaDefault('DefaultOutJsonFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName = [ScubaConfig]::ScubaDefault('DefaultOutCsvFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName = [ScubaConfig]::ScubaDefault('DefaultOutActionPlanFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $SilenceBODWarnings,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate = [ScubaConfig]::ScubaDefault('DefaultNumberOfUUIDCharactersToTruncate'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Transcript
        )
        process {
            $ParentPath = Split-Path $PSScriptRoot -Parent
            $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $ParentPath -ChildPath 'ScubaGear.psd1' -Resolve)
            $ModuleVersion = $ScubaManifest.ModuleVersion

            if ($Version) {
                Write-Output("SCuBA Gear v$ModuleVersion")
                return
            }

            # Initialize logging flag - actual initialization happens after output folder is confirmed
            $Script:ScubaLoggingEnabled = $false

            if ($ProductNames -eq '*'){
                $ProductNames = "aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams", "powerbi"
            }

            if ($OutCsvFileName -eq $OutActionPlanFileName) {
                $ErrorMessage = "OutCsvFileName and OutActionPlanFileName cannot be equal to each other. "
                $ErrorMessage += "Both are set to $($OutCsvFileName). Stopping execution."
                throw $ErrorMessage
            }

            # Create outpath if $Outpath does not exist
            if(-not (Test-Path -PathType "container" $OutPath))
            {
                New-Item -ItemType "Directory" -Path $OutPath | Out-Null
            }
            $OutFolderPath = $OutPath
            $ProductNames = $ProductNames | Sort-Object -Unique

            Remove-Resources
            Import-Resources # Imports Providers, RunRego, etc.

            # Initialize logging for troubleshooting - debug logs are ALWAYS created
            # Logs are placed in a DebugLogs subfolder within the output folder
            # Transcript logging is optional and enabled only when -Transcript is specified
            try {
                # Create debug logs folder within the output folder
                $ScubaLogFolder = Join-Path -Path $OutFolderPath -ChildPath "DebugLogs"

                # Initialize logging WITH tracing for detailed logs
                # Transcript is only enabled if -Transcript switch was used
                if ($Transcript) {
                    Initialize-ScubaLogging -LogPath $ScubaLogFolder -EnableTracing -LogLevel "Debug" -Transcript
                }
                else {
                    Initialize-ScubaLogging -LogPath $ScubaLogFolder -EnableTracing -LogLevel "Debug"
                }

                $Script:ScubaLoggingEnabled = $true
                Write-ScubaLog -Message "ScubaGear logging initialized (Cached Mode)" -Level "Info" -Source "ScubaCached" -Data @{
                    Version = $ModuleVersion
                    ProductNames = ($ProductNames -join ', ')
                    UserPassedEnvironment = $M365Environment
                    OutputFolder = $OutFolderPath
                    LogFolder = $ScubaLogFolder
                    ExportProvider = $ExportProvider
                    TranscriptEnabled = $Transcript
                }
                Write-ScubaLog -Message "Output folder confirmed at $OutFolderPath" -Level "Debug" -Source "ScubaCached" -Data @{OutFolderPath = $OutFolderPath}

                # Log cmdlet invocation details to capture how ScubaGear was invoked
                $InvocationParams = @{}
                foreach ($key in $PSBoundParameters.Keys) {
                    # Mask sensitive values for security
                    if ($key -in @('CertThumbprintParams', 'ClientSecretParams')) {
                        $InvocationParams[$key] = '***REDACTED***'
                    }
                    else {
                        $InvocationParams[$key] = $PSBoundParameters[$key]
                    }
                }
                Write-ScubaLog -Message "Cmdlet invocation captured (Cached Mode)" -Level "Info" -Source "ScubaCached" -Data @{
                    Command = $MyInvocation.MyCommand.Name
                    Parameters = $InvocationParams
                    BoundParameterCount = $PSBoundParameters.Count
                    InvocationLine = $MyInvocation.Line
                }

                # Capture environment diagnostics using Write-ScubaRunDetails
                Write-ScubaLog -Message "Capturing environment diagnostics (Cached Mode)" -Level "Info" -Source "ScubaCached"
                try {
                    Write-ScubaRunDetails -IncludeLoadedModules -IncludeErrors -ConfiguredOPAPath $OPAPath -TestNetworkConnectivity $false -ErrorAction Stop
                }
                catch {
                    Write-ScubaLog -Message "Failed to capture environment diagnostics" -Level "Warning" -Source "ScubaCached" -Data @{
                        Error = $_.Exception.Message
                        StackTrace = $_.ScriptStackTrace
                    }
                }
            }
            catch {
                Write-ScubaLog -Message "Failed to initialize ScubaGear logging" -Level "Warning" -Source "ScubaCached" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                Write-Warning "Failed to initialize ScubaGear logging: $_"
                $Script:ScubaLoggingEnabled = $false
            }

            # Authenticate - parameters consolidated into a temporary ScubaConfig for cached execution
            $TempScubaConfig = New-Object -Type PSObject -Property @{
                'ProductNames' = $ProductNames;
                'M365Environment' = $M365Environment;
                'OutProviderFileName' = $OutProviderFileName;
                'OutRegoFileName' = $OutRegoFileName;
                'OutReportName' = $OutReportName;
                'OPAPath' = $OPAPath;
                'LogIn' = $LogIn;
                'AppID' = $AppID;
                'CertificateThumbprint' = $CertificateThumbprint;
                'Organization' = $Organization;
                'KeepIndividualJSON' = $KeepIndividualJSON;
                'OutJsonFileName' = $OutJsonFileName;
                'OutCsvFileName' = $OutCsvFileName;
                'OutActionPlanFileName' = $OutActionPlanFileName;
                'NumberOfUUIDCharactersToTruncate' = $NumberOfUUIDCharactersToTruncate
            }

            # If user is authenticating with service principal, automatically detect the M365Environment using Microsoft's openid-configuration API
            # This overrides any user provided command line value for M365Environment and the default value of "commercial"
            if ($TempScubaConfig.CertificateThumbprint -or $TempScubaConfig.AppID) {
                # Get-ServicePrincipalParams will validate that CertificateThumbprint, AppID, and Organization are all provided
                $null = Get-ServicePrincipalParams -ScubaConfig $TempScubaConfig
                $TempScubaConfig.M365Environment = Get-M365EnvironmentByDomain -TenantDomain $TempScubaConfig.Organization
            }

            try {
                if ($ExportProvider) {
                    Write-ScubaLog -Message "ExportProvider enabled - will authenticate and export provider data" -Level "Info" -Source "ScubaCached"

                    # Check if there is a previous ScubaResults file
                    # delete if found
                    $PreviousResultsFiles = Get-ChildItem -Path $OutPath -Filter "$($OutJsonFileName)*.json"
                    if ($PreviousResultsFiles) {
                        $PreviousResultsFiles | ForEach-Object {
                            Remove-Item $_.FullName -Force
                        }
                        Write-ScubaLog -Message "Removed $($PreviousResultsFiles.Count) previous result file(s)" -Level "Debug" -Source "ScubaCached"
                    }

                # logging product authentication start with details on which products are being authenticated, the environment, and whether service principal auth is being used
                Write-ScubaLog -Message "Starting product authentication" -Level "Info" -Source "ScubaCached" -Data @{
                    ProductNames = ($ProductNames -join ', ')
                    M365Environment = $TempScubaConfig.M365Environment
                    UsesServicePrincipal = ($null -ne $TempScubaConfig.AppID)
                }

                $ConnectionResult = Invoke-Connection -ScubaConfig $TempScubaConfig
                $ProdAuthFailed = $ConnectionResult.ProdAuthFailed
                if ($ProdAuthFailed.Count -gt 0) {
                    Write-ScubaLog -Message "Some products failed authentication" -Level "Warning" -Source "ScubaCached" -Data @{FailedProducts = ($ProdAuthFailed -join ', ')}

                    # Check if ALL products failed authentication
                    $Difference = Compare-Object $ProductNames -DifferenceObject $ProdAuthFailed -PassThru
                    if (-not $Difference) {
                        # All products failed - log critical error (triggers automatic report generation in Stop-ScubaLogging)
                        Write-ScubaLog -Message "CRITICAL: All products failed authentication - aborting execution" -Level "Error" -Source "ScubaCached" -Data @{
                            RequestedProducts = ($ProductNames -join ', ')
                            FailedProducts = ($ProdAuthFailed -join ', ')
                        }
                        # Stop logging and generate error report before exiting
                        Stop-ScubaLogging
                        return
                    }

                    # Some products succeeded - continue with the successful ones
                    $ProductNames = $Difference
                }
                else {
                    Write-ScubaLog -Message "All products authenticated successfully" -Level "Info" -Source "ScubaCached"
                }

                # Capture module snapshot after authentication to see what modules were imported
                if ($Script:ScubaLoggingEnabled) {
                    try {
                        Update-ScubaModuleSnapshot -SnapshotName "PostAuthentication"
                    }
                    catch {
                        Write-ScubaLog -Message "Failed to capture post-authentication module snapshot" -Level "Warning" -Source "ScubaCached" -Data @{
                            Error = $_.Exception.Message
                        }
                    }
                }

                Write-ScubaLog -Message "Retrieving tenant details" -Level "Info" -Source "ScubaCached"
                $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $TempScubaConfig.M365Environment -ConnectionResult $ConnectionResult

                # A new GUID needs to be generated if the provider is run
                $Guid = New-Guid -ErrorAction 'Stop'

                Write-ScubaLog -Message "Starting provider execution" -Level "Info" -Source "ScubaCached" -Data @{
                    ProductNames = ($ProductNames -join ', ')
                    ModuleVersion = $ModuleVersion
                    Guid = $Guid
                }
                Invoke-ProviderList -ScubaConfig $TempScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -ConnectionResult $ConnectionResult
                Write-ScubaLog -Message "Provider execution completed" -Level "Info" -Source "ScubaCached"
            }
            else {
                Write-ScubaLog -Message "ExportProvider disabled - using cached provider data" -Level "Info" -Source "ScubaCached"
            }

            #####################################
            # If a ScubaResults file exists we grab its System.IO.FileInfo object which is referenced further down.
            #####################################
            $ScubaResultsFileNameWildcard = Join-Path -Path $OutPath -ChildPath "$($OutJsonFileName)*.json"
            $ScubaResultsFileFound = $false
            $ScubaResultsFileObject = $null
            if (Test-Path $ScubaResultsFileNameWildcard) {
                $ScubaResultsFilesArray = @(Get-ChildItem $ScubaResultsFileNameWildcard)
                if ($ScubaResultsFilesArray.Count -gt 1) {
                    throw "You must only have a single ScubaResults file in this folder: $OutPath"
                }
                $ScubaResultsFileObject = $ScubaResultsFilesArray[0]
                $ScubaResultsFileFound = $true
            }
            #####################################

            #####################################
            # In this section we load the Provider file into an object and repair it from invalid JSON if necessary.
            #####################################
            $ProviderJSONFilePath = Join-Path -Path $OutPath -ChildPath "$OutProviderFileName.json"
            # ProjectSettingsObject keeps a PowerShell object of the provider JSON in memory so we can reference its properties such as tenant_details further down.
            $ProviderSettingsObject = $null
            # If the provider output does not exist as a file, extract it from the ScubaResults file .Raw section so downstream functions that rely on it can execute.
            if (-not (Test-Path $ProviderJSONFilePath)) {
                Write-ScubaLog -Message "Provider JSON file not found so extracting from ScubaResults" -Level "Info" -Source "ScubaCached"
                if (-not $ScubaResultsFileFound) {
                    throw "No provider JSON or ScubaResults JSON file was found in folder: $OutPath. Double check the values you passed for -OutPath or -OutProviderFileName to ensure one of those file exists in that folder."
                }
                # Import the full ScubaResults file into a PowerShell object and fix any invalid JSON
                $ImportedObject = Repair-ScubaGearJson -FilePath $ScubaResultsFileObject.FullName
                $ScubaResultsObject = $ImportedObject.JsonObject

                # The provider settings are inside the ScubaResults object in the "Raw": { } property
                $ProviderSettingsObject = $ScubaResultsObject.Raw

                # The provider JSON is already repaired earlier when ScubaResults was loaded so just save to disk so downstream functions can use it.
                $ProviderSettingsString = $ProviderSettingsObject | ConvertTo-Json -Depth 20
                $ActualSavedLocation = Set-Utf8NoBom -Content $ProviderSettingsString -Location $OutPath -FileName "$OutProviderFileName.json"
                Write-Debug $ActualSavedLocation
            }
            # The provider file already exists so load its contents into the ProjectSettingsObject object and repair invalid JSON fields and save it back to disk for downstream use.
            else {
                $ImportedObject = Repair-ScubaGearJson -FilePath $ProviderJSONFilePath
                $ProviderSettingsObject = $ImportedObject.JsonObject
                # If the JSON was repaired as it loaded, save the repaired version back to disk so downstream functions won't crash from invalid JSON.
                if ($ImportedObject.RepairedJson) {
                    $ProviderSettingsString = $ProviderSettingsObject | ConvertTo-Json -Depth 20
                    $ActualSavedLocation = Set-Utf8NoBom -Content $ProviderSettingsString -Location $OutPath -FileName "$OutProviderFileName.json"
                    Write-Debug $ActualSavedLocation
                }
            }
            #####################################

            #####################################
            # If ScubaResults file exists and KeepIndividualJSON then rename ScubaResults file so it is ignored by functions that look for it; Otherwise it can cause conflicts.
            # If the user passes KeepIndividualJSON it signals that they do not want a ScubaResults file generated or processed by ScubaCached.
            if ($ScubaResultsFileFound -and $KeepIndividualJSON) {
                $NewScubaResultsName = "Unused-$($ScubaResultsFileObject.Name)"
                $NewScubaResultsPath = Join-Path $ScubaResultsFileObject.DirectoryName $NewScubaResultsName
                if (Test-Path $NewScubaResultsPath) {
                    Remove-Item $NewScubaResultsPath -Force
                }
                Rename-Item -Path $ScubaResultsFileObject.FullName -NewName $NewScubaResultsName
                Write-Warning "Detected a ScubaResults file along with a ProviderSettingsExport file when calling with the -KeepIndividualJSON parameter."
                Write-Warning "Renamed the ScubaResults to $NewScubaResultsName to avoid ambiguous results. ScubaCached will use the ProviderSettingsExport file since that takes priority."
            }
            #####################################

            Write-ScubaLog -Message "Starting Rego verification" -Level "Info" -Source "ScubaCached" -Data @{
                ProductNames = ($TempScubaConfig.ProductNames -join ', ')
            }
            Invoke-RunRego -ScubaConfig $TempScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath
            Write-ScubaLog -Message "Rego verification completed" -Level "Info" -Source "ScubaCached"

            Write-ScubaLog -Message "Starting report creation" -Level "Info" -Source "ScubaCached"
            Invoke-ReportCreation -ScubaConfig $TempScubaConfig -TenantDetails $ProviderSettingsObject.tenant_details -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode -Quiet:$Quiet

            $FullNameParams = @{
                'OutJsonFileName'                  = $TempScubaConfig.OutJsonFileName;
                'Guid'                             = $ProviderSettingsObject.report_uuid;
                'NumberOfUUIDCharactersToTruncate' = $TempScubaConfig.NumberOfUUIDCharactersToTruncate;
            }
            $FullScubaResultsName = Get-FullOutJsonName @FullNameParams

            # If KeepIndividualJSON is NOT passed, Merge-JsonOutput will create a fresh ScubaResults file.
            if (-not $KeepIndividualJSON) {
                # Craft the complete json version of the output
                $JsonParams = @{
                    'ProductNames'         = $TempScubaConfig.ProductNames;
                    'OutFolderPath'        = $OutFolderPath;
                    'OutProviderFileName'  = $TempScubaConfig.OutProviderFileName;
                    'TenantDetails'        = $ProviderSettingsObject.tenant_details;
                    'ModuleVersion'        = $ModuleVersion;
                    'FullScubaResultsName' = $FullScubaResultsName;
                    'Guid'                 = $ProviderSettingsObject.report_uuid;
                    'SilenceBODWarnings'   = $SilenceBODWarnings;
                }
                # Create a fresh copy of the ScubaResults file with the results and provider settings merged
                Merge-JsonOutput @JsonParams
            }
            # Craft the csv version of just the results
            $CsvParams = @{
                'ProductNames'          = $TempScubaConfig.ProductNames;
                'OutFolderPath'         = $OutFolderPath;
                'FullScubaResultsName'  = $FullScubaResultsName;
                'OutCsvFileName'        = $TempScubaConfig.OutCsvFileName;
                'OutActionPlanFileName' = $TempScubaConfig.OutActionPlanFileName;
            }
            ConvertTo-ResultsCsv @CsvParams
        }
        finally {
            # Clean up debug logging module
            try {
                Write-ScubaLog -Message "ScubaGear assessment completed! Check report in [$OutFolderPath]" -Level "Info" -Source "ScubaCached"
                Stop-ScubaLogging
            }
            catch {
                Write-ScubaLog -Message "Failed to stop ScubaGear logging" -Level "Warning" -Source "ScubaCached" -Data @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
                $Script:ScubaLoggingEnabled = $false
            }
        }
    }
}

function Repair-ScubaGearJson {
    <#
    .SYNOPSIS
    Imports a Provider or ScubaResults JSON file and returns a PowerShell object of the JSON along with metadata indicating whether the JSON required automatic repair.

    .DESCRIPTION
    If the JSON parser detects a known malformed JSON pattern where a property has a
    colon but no value, the function attempts to repair the JSON by treating the missing
    value as an empty array. For example:

        "privileged_service_principals": ,

    is repaired as:

        "privileged_service_principals": []

    If the repaired JSON still cannot be parsed, the function throws a detailed error
    message containing the original parser error, the parser error after repair, and
    manual troubleshooting instructions.

    .PARAMETER Path
    The full path to the provider JSON or ScubaResults file to import.

    .OUTPUTS
    The function returns a PSCustomObject with the following properties:

    - JsonObject (PSCustomObject)
        The PowerShell object created from the provider JSON.

    - RepairedJson (System.Boolean)
        A Boolean indicating whether the JSON file required automatic repair before
        it could be successfully parsed.

    .EXAMPLE
    $ReturnObject = Repair-ScubaGearJson -FilePath $ProviderJSONFilePath

    if ($ReturnObject.RepairedJson) {
        Write-Warning "The provider JSON file required automatic repair."
    }
    
    $ProviderJsonObject = $ProviderSettingsObject.JsonObject

    .EXAMPLE
    $ProviderJSONString = "{ JSON STRING IS HERE }"
    $ReturnObject = Repair-ScubaGearJson -JsonInputString $ProviderJSONString

    if ($ProviderSettingsObject.RepairedJson) {
        Write-Warning "The JSON string required automatic repair."
        $RepairedJSONString = $ProviderSettingsObject.JsonString
    }
    else {
        Write-Warning "The JSON string did not require repair."
    }

    .FUNCTIONALITY
    Private
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string] $FilePath = $null,

        [Parameter(Mandatory = $false)]
        [string] $JsonInputString = $null
    )

    if ((-not $FilePath -and -not $JsonInputString) -or ($FilePath -and $JsonInputString)) {
        throw "Repair-ScubaGearJson: You must specify exactly one of -FilePath or JsonInputString."
    }

    $ReturnObject = [PSCustomObject]@{
        RepairedJson = $false
        JsonObject   = $null
        JsonString = $null
    }

    # We are parsing a JSON file
    if ($FilePath) {
        # The -Raw parameter returns a large string instead of an array of strings which makes the pipeline processing faster for ConvertFrom-Json
        $JsonString = Get-Content $FilePath -Encoding UTF8 -Raw
    }
    # We are parsing a JSON string
    else {
        $JsonString = $JsonInputString
    }

    try {
        # In this block is Attempt number 1 to parse the JSON string

        $JsonReturnObject = $JsonString | ConvertFrom-Json -ErrorAction Stop
        # We are parsing a JSON file so return the JSON converted into a PS Object
        if ($FilePath) {
             $ReturnObject.JsonObject = $JsonReturnObject
        }
        # We are parsing a JSON string so return the string as-is since we didn't need to repair it
        else {
            $ReturnObject.JsonString = $JsonInputString
        }
       
        return $ReturnObject
    }
    catch {
        # If attempt 1 fails, we see if the error is a known message which indicates an invalid JSON string that we have seen before from the export providers.
        # If the error is the known JSON primitive problem then we try to repair it, otherwise we throw the error since it may be some other problem that cannot be auto repaired.
        $OriginalErrorText = $_.Exception.Message

        if ($OriginalErrorText -notmatch 'Invalid JSON primitive') {
            throw
        }

        if ($FilePath) {
        # The -Raw parameter returns a large string instead of an array of strings which makes the pipeline processing faster for ConvertFrom-Json
            Write-Warning "Repair-ScubaGearJson: ScubaGear detected an invalid JSON object at the file: $FilePath"
        }
        else {
            Write-Warning "Repair-ScubaGearJson: ScubaGear detected an invalid JSON object"
        }
        
        Write-Warning "Please report this to the ScubaGear team as a bug report either by GitHub or the Scuba mailbox."
        Write-Warning "Attempting to auto repair the JSON..."

        # Fix any quoted JSON property that has a colon but no value:
        #   "some_property": ,      becomes     "some_property": [],
        #   "some_property": }      becomes     "some_property": []
        $RepairedJsonString = [regex]::Replace(
            $JsonString,
            '("[^"]+"\s*:\s*)(?=,|\})',
            '$1[]'
        )

        try {
            # In this block is Attempt 2. We try to parse the repaired JSON. If it works we return the fixed PS object or the fixed string, depending on what the caller needs.
            if ($FilePath) {
                $RepairedJsonObject = $RepairedJsonString | ConvertFrom-Json -ErrorAction Stop
                Write-Warning "Auto repair of invalid JSON succeeded."
                $ReturnObject.RepairedJson = $true
                $ReturnObject.JsonObject = $RepairedJsonObject
                return $ReturnObject
            }
            else {
                Write-Warning "Auto repair of invalid JSON succeeded."
                $ReturnObject.RepairedJson = $true
                $ReturnObject.JsonString = $RepairedJsonString
                return $ReturnObject
            }
        }
        catch {
            $RepairErrorText = $_.Exception.Message

            throw @"
ScubaGear created an invalid JSON export string, and the automatic repair attempt did not resolve it.

Original JSON parser error:
$OriginalErrorText

Parser error after automatic repair:
$RepairErrorText

What the automatic repair attempted:
The importer looked for JSON properties with a missing value, such as:

    "privileged_service_principals": ,

and temporarily treated them as empty arrays:

    "privileged_service_principals": []

You can attempt to fix the JSON file manually before contacting the Scuba team:
1. Open the JSON file listed above.
2. Search for properties that have a colon but no value.
3. Empty arrays should use [].
4. Empty objects should use {}.
5. Strings should be quoted.
6. Boolean values should be true or false.
7. Null values should be null.

After correcting the JSON file, rerun ScubaGear but use Invoke-ScubaCached since that can create a report from a local JSON file.
"@
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-SCuBA',
    'Invoke-SCuBACached'
)
