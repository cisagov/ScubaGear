Import-Module Microsoft.Identity.Client
Add-Type -AssemblyName System.Security

$TenantNickname = "TENANT_DOMAIN_PREFIX_GOES_HERE"
$Tenant = "TENANT_DOMAIN_PREFIX_GOES_HERE.onmicrosoft.com"
#$ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"  # ms graph SDK
$ClientId = "d9c8596d-08d4-47f6-8812-11687219b138"	# This is the Entra Id registered application GUID in the tenant that the script will use to authenticate

class Msal {
    <# 
    This is a streamlined class for acquiring MSAL access tokens given a specific resource url, 
    such as https://$tenant-admin.sharepoint.com. It always requests the default scopes.
    #>
    [string] $Tenant
    [string] $ClientId
    [Microsoft.Identity.Client.PublicClientApplication] $_publicClientApplication 

    Msal([string]$Tenant, [string]$ClientId) {
        $this.Tenant = $Tenant
        $this.ClientId = $ClientId
    }

    <# -------------------------------------------------------------------------------------------------------
       Cached public application objections. Each has a token cache.
    --------------------------------------------------------------------------------------------------------#>
    [Microsoft.Identity.Client.PublicClientApplication] PublicClientApplication() {
        # Return a (cached) public client application.
        if ($this._publicClientApplication -eq $null) {
            $builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($this.ClientId)
            [void] $builder.WithRedirectUri("http://localhost")
            [void] $builder.WithRedirectUri("https://oath.spops.microsoft.com")
            $this._publicClientApplication = $builder.Build()
        }
        return $this._publicClientApplication
    } 

    <# -------------------------------------------------------------------------------------------------------
       Authentication stuff below.
    --------------------------------------------------------------------------------------------------------#> 
    [string[]] GetDefaultScopes([string]$ResourceUri) {
        # Return the default scopes string for this endpoint, wrapped in a list.
        $uri = New-Object System.Uri $ResourceUri
        return "$($uri.Scheme)://$($uri.Host)/.default"
    }

    [string] GetTokenSilent([string]$ResourceUri, $application) {
        # Tries to use a cached token to get a different token without further user interaction, if possible.
        write-host "get token silent $ResourceUri"
        $Scopes = $this.GetDefaultScopes($ResourceUri)
        [Microsoft.Identity.Client.IAccount] $Account = $application.GetAccountsAsync().GetAwaiter().GetResult() | Select-Object -First 1
        $AcquireTokenParameters = $application.AcquireTokenSilent($Scopes, $Account)
        $AcquireTokenParameters.WithAuthority(('https://{0}' -f $application.AppConfig.Authority.AuthorityInfo.Host), $this.Tenant)
        return $this.ExecuteTask($AcquireTokenParameters)
    }

    [string] GetTokenInteractive([string]$ResourceUri) {
        try {
            return $this.GetTokenInteractivePowershellHack($ResourceUri)
        } catch {
            return $this.GetTokenInteractivePowershellHack($ResourceUri)
        }
    }
    [string] GetTokenInteractivePowershellHack([string]$ResourceUri) {
        write-host "get token interactive $ResourceUri"
        try {
            return $this.GetTokenSilent($ResourceUri, $this.PublicClientApplication())
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException] {
            Write-host "Couldn't get token from the cache. Trying interactive."
        }
        $Scopes = $this.GetDefaultScopes($ResourceUri)
        $AcquireTokenParameters = $this.PublicClientApplication().AcquireTokenInteractive($Scopes)

        # Thanks to github.com/AzureAD/MSAL.PS/src/Get-MsalToken.ps1. This has to do with the popup authentication window where the user enters their credentials.
        [IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
        if ($ParentWindow -eq [System.IntPtr]::Zero -and [System.Environment]::OSVersion.Platform -eq 'Win32NT') {
            $Win32Process = Get-CimInstance Win32_Process -Filter ("ProcessId = '{0}'" -f [System.Diagnostics.Process]::GetCurrentProcess().Id) -Verbose:$false
            $ParentWindow = (Get-Process -Id $Win32Process.ParentProcessId).MainWindowHandle
        }
        if ($ParentWindow -ne [System.IntPtr]::Zero) { 
            [void] $AcquireTokenParameters.WithParentActivityOrWindow($ParentWindow) 
        }
        $AcquireTokenParameters.WithAuthority("https://login.microsoftonline.com/$($this.Tenant)")
        return $this.ExecuteTask($AcquireTokenParameters)
    }

    [string] GetTokenCertificate([string]$ResourceUri, [string]$CertificateThumbprint) {
        # --------------------------------------------------------------------------------------------------
        # Step 1: Load the cert by thumbprint.
        # -------------------------------------------------------------------------------------------------- 
        # Apply some defaults for the cert store location.
        $CertificateStoreLocation = "CurrentUser"
        $CertificateStoreName = "My"

        # Paperwork to get the cert by thumbprint.
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($CertificateStoreName, $CertificateStoreLocation)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        $certificate = $store.Certificates.Find(
          [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
          $CertificateThumbprint,
          $false
        )
        if ($certificate) {
            Write-Host "Using certificate: $($certificate.Subject)"
        } else {
            Write-Error "Certificate with thumbprint '$CertificateThumbprint' not found in '$CertificateStoreName' or '$CertificateStoreLocation'."
        }
        # Close the store.
        $store.Close()
        # Get the actual X509 object from the collection...
        $certificate = $certificate[0]
        # --------------------------------------------------------------------------------------------------
        # Step 2: Do the cert authentication.
        # -------------------------------------------------------------------------------------------------- 
        # There doesn't seem to be much point in caching the confidential client app, so create a new one.
        # The cert has to be added to the builder as well, so can't cache in the case of a different cert.
        $builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($this.ClientId)
        [void] $builder.WithCertificate($certificate)
        [void] $builder.WithRedirectUri("http://localhost")
        $ClientApplication = $builder.Build()
        try {
            return $this.GetTokenSilent($ResourceUri, $ClientApplication)
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException] {
            # Nothin in the token cache...do nothing.
        }
        $Scopes = $this.GetDefaultScopes($ResourceUri)
        $AcquireTokenParameters = $ClientApplication.AcquireTokenForClient($Scopes)
        #$authority = "https://login.microsoftonline.com/$($this.Tenant)"
        #write-host "Authority is $authority"
        #$AcquireTokenParameters.WithAuthority($authority, $this.Tenant)
        return $this.ExecuteTask($AcquireTokenParameters)
    }

    [string] ExecuteTask($AcquireTokenParameters) {
        ## Wait for async task to complete
        $tokenSource = New-Object System.Threading.CancellationTokenSource
        try {
            $taskAuthenticationResult = $AcquireTokenParameters.ExecuteAsync($tokenSource.Token)
            try {
                # Set up the timeout params.
                $Timeout = New-TimeSpan -Minutes 2
                $endTime = [datetime]::Now.Add($Timeout)

                # Poll the task for various completion or failure scenarios.
                while (!$taskAuthenticationResult.IsCompleted) {

                    # Cancel if the timeout has expired.
                    if ($Timeout -eq [timespan]::Zero -or [datetime]::Now -lt $endTime) {
                        Start-Sleep -Seconds 1
                    }
                    else {
                        $tokenSource.Cancel()

                        # Hang out for a bit. Log any errors that happen.
                        try { 
                            $taskAuthenticationResult.Wait() 
                        }
                        catch { 
                            Write-Error -Exception (New-Object System.TimeoutException) -Category ([System.Management.Automation.ErrorCategory]::OperationTimeout) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationTimeout' -TargetObject $AcquireTokenParameters -ErrorAction Stop
                        }
                    }
                }
            }
            finally {
                if (!$taskAuthenticationResult.IsCompleted) {
                    Write-Debug ('Canceling Token Acquisition for Application with ClientId [{0}]' -f $this.ClientId)
                    $tokenSource.Cancel()
                }
                $tokenSource.Dispose()
            }

            ## Parse task results
            if ($taskAuthenticationResult.IsFaulted) {
                Write-Error -Exception $taskAuthenticationResult.Exception -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AcquireTokenParameters -ErrorAction Stop
            }
            if ($taskAuthenticationResult.IsCanceled) {
                Write-Error -Exception (New-Object System.Threading.Tasks.TaskCanceledException $taskAuthenticationResult) -Category ([System.Management.Automation.ErrorCategory]::OperationStopped) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationStopped' -TargetObject $AcquireTokenParameters -ErrorAction "Stop"
            }
            else {
                return $taskAuthenticationResult.Result.AccessToken
            }
        }
        catch {
            function Coalesce([psobject[]]$objects) { foreach ($object in $objects) { if ($object -notin $null, [string]::Empty) { return $object } } return $null }
            Write-Error -Exception (Coalesce $_.Exception.InnerException,$_.Exception) -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AcquireTokenParameters -ErrorAction "Stop"
        }
        throw "Authentication failed. See error message."
    }

    [System.Object] Request($uri, $method, $headers) {
        if ($headers -eq $null) {
            $headers = @{}
        }
        $token = $this.GetTokenInteractive($uri)
        write-host $token
        $headers["Authorization"] = "Bearer $token"
        $jsonheaders = ($headers | ConvertTo-Json)
        write-host "headers are $jsonheaders"

        $resp = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers
        return $resp
    }
}


class ApiClient {
    <# This class fetches Microsoft REST API resources, adding a fresh access token header to each request. 
    #>
    [Msal] $Msal

    ApiClient([MSAL] $Msal) {
        $this.Msal = $Msal
    }
  
    [System.Object] Request($uri, $method, $body, $headers) {
        if ($headers -eq $null) {
            $headers = @{}
        }
        $zibble = $this.Msal.GetTokenInteractive($uri)
        write-host $zibble
        $headers["Authorization"] = "Bearer $zibble"
        $jsonheaders = ($headers | ConvertTo-Json)
        write-host "headers are $jsonheaders"
        $resp = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body $body
        return $resp
    }
}

##### Sample code to use the classes defined above
##########

$msal = [Msal]::new($Tenant, $ClientId)
$api = [ApiClient]::new($msal)
#$uri = "https://$($TenantNickname)-admin.sharepoint.com/_api/Web/CurrentUser"
$uri = "https://$($TenantNickname)-admin.sharepoint.com/_vti_bin/client.svc/ProcessQuery"
# This HTTP request body is needed in the call to the back-end Sharepoint REST API
$body = @'
  <Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName=".NET Library" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009">
    <Actions>
      <ObjectPath Id="2" ObjectPathId="1" />
      <Query Id="3" ObjectPathId="1">
        <Query SelectAllProperties="true">
          <Properties>
            <Property Name="HideDefaultThemes" ScalarProperty="true" />
          </Properties>
        </Query>
      </Query>
    </Actions>
    <ObjectPaths>
      <Constructor Id="1" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" />
    </ObjectPaths>
  </Request>
'@
$headers =  @{
  "Accept-Encoding" = "gzip, deflate"
  "Content-Type" = "text/xml"
  "User-Agent" = "ScubaGear"
}

# Get an authentication token and then call the back-end Sharepoint API
$resp = $api.Request($uri, "POST", $body, $headers)
# Display the response from the Sharepoint API
$resp



