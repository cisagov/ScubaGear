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
    Version = '4.89.0'
    # Subject substring every bundled assembly's Authenticode signer must contain.
    SignerOrganization = 'O=Microsoft Corporation'
    # Full net462 dependency closure. LibPath is the entry inside the .nupkg; TargetDll is the
    # file name written to the cache; Purpose documents why each assembly is present. Everything
    # after Microsoft.IdentityModel.Abstractions is pulled in transitively (mostly by System.Text.Json).
    Packages = @(
        @{ Id = 'Microsoft.Identity.Client';               Version = '4.89.0'; Sha256 = '379A9B9151472A7CB290FB4DF092D82F840FE1A799C4AE1337CABC249837743E'; LibPath = 'lib/net462/Microsoft.Identity.Client.dll';               TargetDll = 'Microsoft.Identity.Client.dll';               Purpose = 'MSAL: acquires OAuth tokens for Microsoft Graph and M365 admin APIs' }
        @{ Id = 'Microsoft.IdentityModel.Abstractions';    Version = '8.14.0'; Sha256 = '6E40AECF55A3E7A37E2C758BBC728B702B4846A04AFB7939BC3DAA7C1EF15CA9'; LibPath = 'lib/net462/Microsoft.IdentityModel.Abstractions.dll';    TargetDll = 'Microsoft.IdentityModel.Abstractions.dll';    Purpose = 'Logging/telemetry abstraction (direct MSAL dependency)' }
        @{ Id = 'System.Diagnostics.DiagnosticSource';     Version = '6.0.1';  Sha256 = '5E2F30AD48D5962A33FFF4CF423147A9C57F406853AA74DF51C96DB0D95C089E'; LibPath = 'lib/net461/System.Diagnostics.DiagnosticSource.dll';     TargetDll = 'System.Diagnostics.DiagnosticSource.dll';     Purpose = 'MSAL diagnostics/telemetry' }
        @{ Id = 'System.Runtime.CompilerServices.Unsafe';  Version = '6.0.0';  Sha256 = '6C41B53E70E9EEE298CFF3A02CE5ACDD15B04125589BE0273F0566026720A762'; LibPath = 'lib/net461/System.Runtime.CompilerServices.Unsafe.dll';  TargetDll = 'System.Runtime.CompilerServices.Unsafe.dll';  Purpose = '.NET Framework low-level memory shim required by System.Text.Json' }
        @{ Id = 'System.ValueTuple';                       Version = '4.5.0';  Sha256 = '9E21FA9767D4E76BC0CEE065C1D40CC34384A114BFEC4D70E6C981168A926802'; LibPath = 'lib/net461/System.ValueTuple.dll';                       TargetDll = 'System.ValueTuple.dll';                       Purpose = '.NET Framework tuple support shim' }
        @{ Id = 'System.Text.Json';                        Version = '6.0.10'; Sha256 = '5228D88747711631629CC3D24C9A1BF7AA1A464366F96B1AFBB15F83A9919EC7'; LibPath = 'lib/net461/System.Text.Json.dll';                        TargetDll = 'System.Text.Json.dll';                        Purpose = 'JSON (de)serialization of token responses on .NET Framework' }
        @{ Id = 'System.Text.Encodings.Web';               Version = '6.0.0';  Sha256 = '51E9831C61684081BB39B430465BA155FE8082D42291F1C4A0F2C2EA06C5C91A'; LibPath = 'lib/net461/System.Text.Encodings.Web.dll';               TargetDll = 'System.Text.Encodings.Web.dll';               Purpose = 'Safe text encoding used by System.Text.Json' }
        @{ Id = 'System.Formats.Asn1';                     Version = '8.0.1';  Sha256 = '99ACBF5A0F9EB269B5375E244131B81123018BE19028FA7466BAC1A3FA3A3973'; LibPath = 'lib/net462/System.Formats.Asn1.dll';                     TargetDll = 'System.Formats.Asn1.dll';                     Purpose = 'ASN.1 parsing for certificate-based authentication' }
        @{ Id = 'System.Memory';                           Version = '4.5.5';  Sha256 = '10F43DA352A29FB2B3188E4EDD4DCF5100194C8B526E4F61FE2E2B5623775A22'; LibPath = 'lib/net461/System.Memory.dll';                           TargetDll = 'System.Memory.dll';                           Purpose = 'Span/Memory shim required by System.Text.Json on .NET Framework' }
        @{ Id = 'System.Buffers';                          Version = '4.5.1';  Sha256 = 'C30B3DD2C7E2F4CEE4B823D692FD42118309B42AB1F5007F923D329A5B0D6B12'; LibPath = 'lib/net461/System.Buffers.dll';                          TargetDll = 'System.Buffers.dll';                          Purpose = 'Buffer pooling shim used by System.Memory/System.Text.Json' }
        @{ Id = 'System.Numerics.Vectors';                 Version = '4.5.0';  Sha256 = 'A9D49320581FDA1B4F4BE6212C68C01A22CDF228026099C20A8EABEFCF90F9CF'; LibPath = 'lib/net46/System.Numerics.Vectors.dll';                  TargetDll = 'System.Numerics.Vectors.dll';                  Purpose = 'SIMD/vector shim used by System.Memory' }
        @{ Id = 'System.Threading.Tasks.Extensions';       Version = '4.5.4';  Sha256 = 'A304A963CC0796C5179F9C6B7D8022BBCE3B2FA7C029EB6196F631F7B462D678'; LibPath = 'lib/net461/System.Threading.Tasks.Extensions.dll';       TargetDll = 'System.Threading.Tasks.Extensions.dll';       Purpose = 'ValueTask support shim for System.Text.Json' }
        @{ Id = 'Microsoft.Bcl.AsyncInterfaces';           Version = '6.0.0';  Sha256 = 'E3DF87FE2170A7E01F0880AF59CAA8F6EB380B3C40A4F282DFB43912AAF0F895'; LibPath = 'lib/net461/Microsoft.Bcl.AsyncInterfaces.dll';           TargetDll = 'Microsoft.Bcl.AsyncInterfaces.dll';           Purpose = 'IAsyncEnumerable support shim for System.Text.Json' }
    )
    # Expected identity of each extracted assembly (SHA-256 + managed assembly version).
    Files = @(
        @{ File = 'Microsoft.Identity.Client.dll';              Sha256 = '964AFB45E3A03856C0BEA62E929464AC2F252A3D942F6B357DC675051D91E847'; AssemblyVersion = '4.89.0.0' }
        @{ File = 'Microsoft.IdentityModel.Abstractions.dll';   Sha256 = 'BF8339F8ACC1E7FFC4E6447550644050157446C8F5DD270AE4786FDF7F39075D'; AssemblyVersion = '8.14.0.0' }
        @{ File = 'System.Diagnostics.DiagnosticSource.dll';    Sha256 = '19BA42737C1C0500373736968F3D15CB7897CB195049FD5F492E6FE1629DAAAB'; AssemblyVersion = '6.0.0.1' }
        @{ File = 'System.Runtime.CompilerServices.Unsafe.dll'; Sha256 = '37768488E8EF45729BC7D9A2677633C6450042975BB96516E186DA6CB9CD0DCF'; AssemblyVersion = '6.0.0.0' }
        @{ File = 'System.ValueTuple.dll';                      Sha256 = 'E4774AEAD2793F440E0CED6C097048423D118E0B6ED238C6FE5B456ACB07817F'; AssemblyVersion = '4.0.3.0' }
        @{ File = 'System.Text.Json.dll';                       Sha256 = 'BDE4850D39245F9758D1346BD67AC890EEC25473B7A7171AD6E631A4C5FD4734'; AssemblyVersion = '6.0.0.10' }
        @{ File = 'System.Text.Encodings.Web.dll';              Sha256 = '78EB5B4FEE580E163D1BEA1FDB7D371FDFCFD30ACD8708FF62C4372AAA219F7C'; AssemblyVersion = '6.0.0.0' }
        @{ File = 'System.Formats.Asn1.dll';                    Sha256 = '84692333CD9E3D9EF2761722A853DC88A412E1E71809744E18639A293C218C8E'; AssemblyVersion = '8.0.0.1' }
        @{ File = 'System.Memory.dll';                          Sha256 = 'BF3FB84664F4097F1A8A9BC71A51DCF8CF1A905D4080A4D290DA1730866E856F'; AssemblyVersion = '4.0.1.2' }
        @{ File = 'System.Buffers.dll';                         Sha256 = 'ACCCCFBE45D9F08FFEED9916E37B33E98C65BE012CFFF6E7FA7B67210CE1FEFB'; AssemblyVersion = '4.0.3.0' }
        @{ File = 'System.Numerics.Vectors.dll';                Sha256 = '1D3EF8698281E7CF7371D1554AFEF5872B39F96C26DA772210A33DA041BA1183'; AssemblyVersion = '4.1.4.0' }
        @{ File = 'System.Threading.Tasks.Extensions.dll';      Sha256 = '4F81FFD0DC7204DB75AFC35EA4291769B07C440592F28894260EEA76626A23C6'; AssemblyVersion = '4.2.0.1' }
        @{ File = 'Microsoft.Bcl.AsyncInterfaces.dll';          Sha256 = '295AF2142D9214F3FD84EAFE4778DCA119BE7E0229F14B6BA8D5269C2F1E2E78'; AssemblyVersion = '6.0.0.0' }
    )
    # Assemblies must be loaded dependency-first (Windows PowerShell only; PowerShell 7 provides System.*).
    LoadOrder = @(
        'System.Buffers.dll'
        'System.Numerics.Vectors.dll'
        'System.Runtime.CompilerServices.Unsafe.dll'
        'System.Threading.Tasks.Extensions.dll'
        'System.ValueTuple.dll'
        'System.Memory.dll'
        'Microsoft.Bcl.AsyncInterfaces.dll'
        'System.Text.Encodings.Web.dll'
        'System.Formats.Asn1.dll'
        'System.Text.Json.dll'
        'System.Diagnostics.DiagnosticSource.dll'
        'Microsoft.IdentityModel.Abstractions.dll'
        'Microsoft.Identity.Client.dll'
    )
}


