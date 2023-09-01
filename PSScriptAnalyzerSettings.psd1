# PSScriptAnalyzerSettings.psd1
@{
    Severity=@('Error','Warning','Information')
    ExcludeRules=@(
      'PSUseSingularNouns',
      'PSUseShouldProcessForStateChangingFunctions',
      'PSUseOutputTypeCorrectly',
      'PSAvoidGlobalVars' # Unable to individually suppress exceptions
      )
}
