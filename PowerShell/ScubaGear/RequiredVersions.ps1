[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
        Purpose = 'YAML file processing and configuration management'
        IsPinned = "False"
    }
)

# Pinned MSAL (Microsoft.Identity.Client) dependency closure. These signed assemblies are not
# bundled in the repo; they are downloaded on demand from NuGet into
# ~/.scubagear/MSAL/<Version>/net462 and verified against the hashes and signer below.
# The Update-Msal workflow rewrites this block when a new version is approved.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MsalDependency')]
$MsalDependency = @{
    Version = '4.82.0'
    # Subject substring every bundled assembly's Authenticode signer must contain.
    SignerOrganization = 'O=Microsoft Corporation'
    # NuGet packages to fetch. LibPath is the entry inside the .nupkg; TargetDll is the file
    # name written to the cache (all normalized into the net462 target folder).
    Packages = @(
        @{ Id = 'Microsoft.Identity.Client';               Version = '4.82.0'; Sha256 = 'CCFF0985700C62EA8EAF84813A6D6A7B8FB81464B161928D30A344C1C6940137'; LibPath = 'lib/net462/Microsoft.Identity.Client.dll';               TargetDll = 'Microsoft.Identity.Client.dll' }
        @{ Id = 'Microsoft.IdentityModel.Abstractions';    Version = '8.14.0'; Sha256 = '6E40AECF55A3E7A37E2C758BBC728B702B4846A04AFB7939BC3DAA7C1EF15CA9'; LibPath = 'lib/net462/Microsoft.IdentityModel.Abstractions.dll';    TargetDll = 'Microsoft.IdentityModel.Abstractions.dll' }
        @{ Id = 'System.Diagnostics.DiagnosticSource';     Version = '6.0.1';  Sha256 = '5E2F30AD48D5962A33FFF4CF423147A9C57F406853AA74DF51C96DB0D95C089E'; LibPath = 'lib/net461/System.Diagnostics.DiagnosticSource.dll';     TargetDll = 'System.Diagnostics.DiagnosticSource.dll' }
        @{ Id = 'System.Runtime.CompilerServices.Unsafe';  Version = '6.0.0';  Sha256 = '6C41B53E70E9EEE298CFF3A02CE5ACDD15B04125589BE0273F0566026720A762'; LibPath = 'lib/net461/System.Runtime.CompilerServices.Unsafe.dll';  TargetDll = 'System.Runtime.CompilerServices.Unsafe.dll' }
        @{ Id = 'System.ValueTuple';                       Version = '4.5.0';  Sha256 = '9E21FA9767D4E76BC0CEE065C1D40CC34384A114BFEC4D70E6C981168A926802'; LibPath = 'lib/net47/System.ValueTuple.dll';                        TargetDll = 'System.ValueTuple.dll' }
    )
    # Expected identity of each extracted assembly (SHA-256 + managed assembly version).
    Files = @(
        @{ File = 'Microsoft.Identity.Client.dll';              Sha256 = 'AEC48455BCB0DB17F9648422D5B7BDF3C988A326A75087F1E6F599002D1A68C8'; AssemblyVersion = '4.82.0.0' }
        @{ File = 'Microsoft.IdentityModel.Abstractions.dll';   Sha256 = 'BF8339F8ACC1E7FFC4E6447550644050157446C8F5DD270AE4786FDF7F39075D'; AssemblyVersion = '8.14.0.0' }
        @{ File = 'System.Diagnostics.DiagnosticSource.dll';    Sha256 = '19BA42737C1C0500373736968F3D15CB7897CB195049FD5F492E6FE1629DAAAB'; AssemblyVersion = '6.0.0.1' }
        @{ File = 'System.Runtime.CompilerServices.Unsafe.dll'; Sha256 = '37768488E8EF45729BC7D9A2677633C6450042975BB96516E186DA6CB9CD0DCF'; AssemblyVersion = '6.0.0.0' }
        @{ File = 'System.ValueTuple.dll';                      Sha256 = 'E905D102585B22C6DF04F219AF5CBDBFA7BC165979E9788B62DF6DCC165E10F4'; AssemblyVersion = '4.0.3.0' }
    )
    # Assemblies must be loaded dependency-first.
    LoadOrder = @(
        'System.Runtime.CompilerServices.Unsafe.dll'
        'System.Diagnostics.DiagnosticSource.dll'
        'Microsoft.IdentityModel.Abstractions.dll'
        'Microsoft.Identity.Client.dll'
    )
}


