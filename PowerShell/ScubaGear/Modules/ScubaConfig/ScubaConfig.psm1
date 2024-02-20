class ScubaConfig {
    <#
    .SYNOPSIS
      This class stores Scuba config data loaded from a file.
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
        DefaultOPAPath = (Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools")
    }

    static [object]ScubaDefault ([string]$Name){
        return [ScubaConfig]::ScubaDefaults[$Name]
    }

    [Boolean]LoadConfig([System.IO.FileInfo]$Path){
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }
        [ScubaConfig]::ResetInstance()
        $Content = Get-Content -Raw -Path $Path
        $this.Configuration = $Content | ConvertFrom-Yaml

        $this.SetParameterDefaults()
        [ScubaConfig]::_IsLoaded = $true

        return [ScubaConfig]::_IsLoaded
    }

    hidden [void]ClearConfiguration(){
        $this.Configuration = $null
    }

    hidden [Guid]$Uuid = [Guid]::NewGuid()
    hidden [hashtable]$Configuration

    hidden [void]SetParameterDefaults(){
        if (-Not $this.Configuration.ProductNames){
            $this.Configuration.ProductNames = @("entraid", "defender", "exo", "sharepoint", "teams")
        }
        else{
            # Transform ProductNames into list of all products if it contains wildcard
            if ($this.Configuration.ProductNames.Contains('*')){
                $this.Configuration.ProductNames = "entraid", "defender", "exo", "powerplatform", "sharepoint", "teams"
                Write-Debug "Setting ProductNames to all products because of wildcard"
            }
            else{
                $this.Configuration.ProductNames = $this.Configuration.ProductNames | Sort-Object
            }
        }

        if (-Not $this.Configuration.M365Environment){
            $this.Configuration.M365Environment = 'commercial'
        }

        if (-Not $this.Configuration.OPAPath){
            $this.Configuration.OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath')
        }

        if (-Not $this.Configuration.LogIn){
            $this.Configuration.LogIn = $true
        }

        if (-Not $this.Configuration.DisconnectOnExit){
            $this.Configuration.DisconnectOnExit = $false
        }

        if (-Not $this.Configuration.OutPath){
            $this.Configuration.OutPath = '.'
        }

        if (-Not $this.Configuration.OutFolderName){
            $this.Configuration.OutFolderName = "M365BaselineConformance"
        }

        if (-Not $this.Configuration.OutProviderFileName){
            $this.Configuration.OutProviderFileName = "ProviderSettingsExport"
        }

        if (-Not $this.Configuration.OutRegoFileName){
            $this.Configuration.OutRegoFileName = "TestResults"
        }

        if (-Not $this.Configuration.OutReportName){
            $this.Configuration.OutReportName = "BaselineReports"
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
