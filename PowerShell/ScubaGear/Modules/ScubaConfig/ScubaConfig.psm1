class ScubaConfig {
    <#
    .SYNOPSIS
    This singleton class stores Scuba config data loaded from a file.
    .DESCRIPTION
    This class is designed to function as a singleton. The singleton instance
    is cached on the ScubaConfig type itself. In the context of tests, it may be
    important to call `.ResetInstance` before and after tests as needed to
    ensure any preexisting configs are not inadvertantly used for the test,
    or left in place after the test is finished. The singleton will persist
    for the life of the powershell session unless the ScubaConfig module is
    removed. Note that `.LoadConfig` internally calls `.ResetInstance` to avoid
    issues.
    .EXAMPLE
    $Config = [ScubaConfig]::GetInstance()
    [ScubaConfig]::LoadConfig($SomePath)
    #>
    hidden static [ScubaConfig]$_Instance = [ScubaConfig]::new()
    hidden static [Boolean]$_IsLoaded = $false
    hidden static [hashtable]$ScubaDefaults = @{
        DefaultOPAPath = try {Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"} catch {"."};
        DefaultProductNames = @("aad", "defender", "exo", "sharepoint", "teams")
        AllProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
        DefaultM365Environment = "commercial"
        DefaultLogIn = $true
        DefaultOutPath = Get-Location | Select-Object -ExpandProperty ProviderPath
        DefaultOutFolderName = "M365BaselineConformance"
        DefaultOutProviderFileName = "ProviderSettingsExport"
        DefaultOutRegoFileName = "TestResults"
        DefaultOutReportName = "BaselineReports"
        DefaultOutJsonFileName = "ScubaResults"
        DefaultOutCsvFileName = "ScubaResults"
        DefaultOutActionPlanFileName = "ActionPlan"
        DefaultNumberOfUUIDCharactersToTruncate = 18
        DefaultPrivilegedRoles = @(
            "Global Administrator",
            "Privileged Role Administrator",
            "User Administrator",
            "SharePoint Administrator",
            "Exchange Administrator",
            "Hybrid Identity Administrator",
            "Application Administrator",
            "Cloud Application Administrator")
        DefaultOPAVersion = '1.5.1'
    }

    static [object]ScubaDefault ([string]$Name){
        return [ScubaConfig]::ScubaDefaults[$Name]
    }

    static [string]GetOpaVersion() {
        return [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
    }

    [Boolean]LoadConfig([System.IO.FileInfo]$Path){
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }
        [ScubaConfig]::ResetInstance()
        $Content = Get-Content -Raw -Path $Path
        try {
            $this.Configuration = $Content | ConvertFrom-Yaml
        }
        catch {
            $ParseError = $($_.Exception.Message) -Replace '^Exception calling "Load" with "1" argument\(s\): ', ''
            throw "Error loading config file: $ParseError"
        }

        $this.SetParameterDefaults()
        [ScubaConfig]::_IsLoaded = $true

        # If OmitPolicy was included in the config file, validate the policy IDs included there.
        if ($this.Configuration.ContainsKey("OmitPolicy")) {
            foreach ($Policy in $this.Configuration.OmitPolicy.Keys) {
                if (-not ($Policy -match "^ms\.[a-z]+\.[0-9]+\.[0-9]+v[0-9]+$")) {
                    # Note that -match is a case insensitive match
                    # Note that the regex does not validate the product name, this will be done later
                    $Warning = "Config file indicates omitting $Policy, but $Policy is not a valid control ID. "
                    $Warning += "Expected format is 'MS.[PRODUCT].[GROUP].[NUMBER]v[VERSION]', "
                    $Warning += "e.g., 'MS.DEFENDER.1.1v1'. Control will not be omitted."
                    Write-Warning $Warning
                    Continue
                }
                $Product = ($Policy -Split "\.")[1]
                # Here's where the product name is validated
                if (-not ($this.Configuration.ProductNames -Contains $Product)) {
                    $Warning = "Config file indicates omitting $Policy, but $Product is not one of the products "
                    $Warning += "specified in the ProductNames parameter. Control will not be omitted."
                    Write-Warning $Warning
                    Continue
                }
            }
        }

        return [ScubaConfig]::_IsLoaded
    }

    hidden [void]ClearConfiguration(){
        $this.Configuration = $null
    }

    hidden [Guid]$Uuid = [Guid]::NewGuid()
    hidden [hashtable]$Configuration

    hidden [void]SetParameterDefaults(){
        Write-Debug "Setting ScubaConfig default values."
        if (-Not $this.Configuration.ProductNames){
            $this.Configuration.ProductNames = [ScubaConfig]::ScubaDefault('DefaultProductNames')
        }
        else{
            # Transform ProductNames into list of all products if it contains wildcard
            if ($this.Configuration.ProductNames.Contains('*')){
                $this.Configuration.ProductNames = [ScubaConfig]::ScubaDefault('AllProductNames')
                Write-Debug "Setting ProductNames to all products because of wildcard"
            }
            else{
                Write-Debug "ProductNames provided - using as is."
                $this.Configuration.ProductNames = $this.Configuration.ProductNames | Sort-Object -Unique
            }
        }

        if (-Not $this.Configuration.M365Environment){
            $this.Configuration.M365Environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment')
        }

        if (-Not $this.Configuration.OPAPath){
            $this.Configuration.OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath')
        }

        if (-Not $this.Configuration.LogIn){
            $this.Configuration.LogIn = [ScubaConfig]::ScubaDefault('DefaultLogIn')
        }

        if (-Not $this.Configuration.DisconnectOnExit){
            $this.Configuration.DisconnectOnExit = $false
        }

        if (-Not $this.Configuration.OutPath){
            $this.Configuration.OutPath = [ScubaConfig]::ScubaDefault('DefaultOutPath')
        }

        if (-Not $this.Configuration.OutFolderName){
            $this.Configuration.OutFolderName = [ScubaConfig]::ScubaDefault('DefaultOutFolderName')
        }

        if (-Not $this.Configuration.OutProviderFileName){
            $this.Configuration.OutProviderFileName = [ScubaConfig]::ScubaDefault('DefaultOutProviderFileName')
        }

        if (-Not $this.Configuration.OutRegoFileName){
            $this.Configuration.OutRegoFileName = [ScubaConfig]::ScubaDefault('DefaultOutRegoFileName')
        }

        if (-Not $this.Configuration.OutReportName){
            $this.Configuration.OutReportName = [ScubaConfig]::ScubaDefault('DefaultOutReportName')
        }

        if (-Not $this.Configuration.OutJsonFileName){
            $this.Configuration.OutJsonFileName = [ScubaConfig]::ScubaDefault('DefaultOutJsonFileName')
        }

        if (-Not $this.Configuration.OutCsvFileName){
            $this.Configuration.OutCsvFileName = [ScubaConfig]::ScubaDefault('DefaultOutCsvFileName')
        }

        if (-Not $this.Configuration.OutActionPlanFileName){
            $this.Configuration.OutActionPlanFileName = [ScubaConfig]::ScubaDefault('DefaultOutActionPlanFileName')
        }

        if (-Not $this.Configuration.NumberOfUUIDCharactersToTruncate){
            $this.Configuration.NumberOfUUIDCharactersToTruncate = [ScubaConfig]::ScubaDefault('DefaultNumberOfUUIDCharactersToTruncate')
        }
        return
    }

    hidden ScubaConfig(){
    }

    static [void]ResetInstance(){
        [ScubaConfig]::_Instance.ClearConfiguration()
        [ScubaConfig]::_IsLoaded = $false
        return
    }

    static [ScubaConfig]GetInstance(){
        return [ScubaConfig]::_Instance
    }
}

