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
        Get-Member -InputObject ($this.Configuration) -Type properties |
          ForEach-Object { $this.Configuration.PSObject.Properties.Remove($_.name)}
    }

    hidden [Guid]$Uuid = [Guid]::NewGuid()
    hidden [hashtable]$Configuration

    hidden [void]SetParameterDefaults(){
        if (-Not $this.Configuration.ProductNames){
            $this.Configuration.ProductNames = "teams", "exo", "defender", "aad", "sharepoint", "powerplatform" | Sort-Object
        }
        else{
            $this.Configuration.ProductNames = $this.Configuration.ProductNames | Sort-Object
        }

        if (-Not $this.Configuration.M365Environment){
            $this.Configuration.M365Environment = 'commercial'
        }

        if (-Not $this.Configuration.OPAPath){
            $this.Configuration.OPAPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..")
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
        if ([ScubaConfig]::_IsLoaded){
            [ScubaConfig]::_Instance.ClearConfiguration()
            [ScubaConfig]::_IsLoaded = $false
        }

        return
    }

    static [ScubaConfig]GetInstance(){
        return [ScubaConfig]::_Instance
    }
}
