

class AssemblyInstallationHelper {
    <# 
    I blame powershell's documentation and Microsoft CoPilot for everything for follows below.

    This class contains functions to download nuget.exe and load DLLs required for MSAL usage.
    #>
    [void] GetNuGet() {
        # Fetch the latest NuGet and dump it in Scuba script root. We can delete later.
        $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
        $targetNugetExe = "$PSScriptRoot\nuget.exe"
        if(![System.IO.File]::Exists($targetNugetExe)) {
            Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
        }
    }

    [void] NuGetRestore() {
        # Downloads the raw NuGet packages.
        & "$PSScriptRoot\nuget.exe" restore -ConfigFile .\NuGet.config
    }

    [void] LoadDlls() {
        # Find the DLLs based on whether this is Core or Desktop powershell. These obvious hacks inspired by MSAL.PS. It works!
        $packages = "$PSScriptRoot\build\packages"
        foreach ($file in (ls $packages)) {
            $subfolderPattern = $null
            Switch ($global:PSVersionTable.PSEdition) {
                'Core'    { $subfolderPattern = "netcoreapp*" }
                'Desktop' { $subfolderPattern = "net4*"}
                Default   { Throw "Unexpected powershell: $global:PSVersionTable.PSEdition" }
            }
            $subfolder = ((ls "$packages\$file\lib\$subfolderPattern\") | select-object -first 1).Name
            $dllpath = "$packages\$file\lib\$subfolder"
            foreach ($dll in (ls $dllpath -Filter "*.dll")) {
                write-host "Loading DLL: $dllpath\$dll"
                try {
                    Add-Type -LiteralPath "$dllpath\$dll"
                } catch {
                    Write-Host "Error message: $($_.Message)"
                    Write-Host "Loader exceptions:"
                    Write-Host ($_.LoaderExceptions | ForEach-Object { $_.Message })
                }
            }
        }
    }
}


$aih = [AssemblyInstallationHelper]::new()
$aih.GetNuGet()
$aih.NuGetRestore()
$aih.LoadDlls()
