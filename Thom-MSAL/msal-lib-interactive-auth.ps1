# Change the values of the two variables below to match your environment
$tenant = "TENANT_DOMAIN_PREFIX_GOES_HERE"
$ClientId = "d9c8596d-08d4-47f6-8812-11687219b138"	# This is the Entra Id registered application GUID in the tenant that the script will use to authenticate

$authority = "https://login.microsoftonline.com/$tenant"
[string[]] $Scopes = "https://$tenant-admin.sharepoint.com/.default"


write-host "create app builder"
$ClientApplicationBuilder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId)
[void] $ClientApplicationBuilder.WithRedirectUri("http://localhost")
$ClientApplication = $ClientApplicationBuilder.Build()

Write-Host ('Adding Application with ClientId [{0}] and RedirectUri [{1}] to cache.' -f $ClientApplication.AppConfig.ClientId, $ClientApplication.AppConfig.RedirectUri)

write-host "start the process of acquiring the token from the user interactively"
$AcquireTokenParameters = $ClientApplication.AcquireTokenInteractive($Scopes)
[IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
if ($ParentWindow -eq [System.IntPtr]::Zero -and [System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    $Win32Process = Get-CimInstance Win32_Process -Filter ("ProcessId = '{0}'" -f [System.Diagnostics.Process]::GetCurrentProcess().Id) -Verbose:$false
    $ParentWindow = (Get-Process -Id $Win32Process.ParentProcessId).MainWindowHandle
}
if ($ParentWindow -ne [System.IntPtr]::Zero) { [void] $AcquireTokenParameters.WithParentActivityOrWindow($ParentWindow) }
write-host "done acquiring token interactively"

function Coalesce([psobject[]]$objects) { foreach ($object in $objects) { if ($object -notin $null, [string]::Empty) { return $object } } return $null }
 
## Wait for async task to complete
$tokenSource = New-Object System.Threading.CancellationTokenSource
try {
    $taskAuthenticationResult = $AcquireTokenParameters.ExecuteAsync($tokenSource.Token)
    try {
	$Timeout = New-TimeSpan -Minutes 2
	$endTime = [datetime]::Now.Add($Timeout)
	while (!$taskAuthenticationResult.IsCompleted) {
	    if ($Timeout -eq [timespan]::Zero -or [datetime]::Now -lt $endTime) {
		Start-Sleep -Seconds 1
	    }
	    else {
		$tokenSource.Cancel()
		try { $taskAuthenticationResult.Wait() }
		catch { }
		Write-Error -Exception (New-Object System.TimeoutException) -Category ([System.Management.Automation.ErrorCategory]::OperationTimeout) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationTimeout' -TargetObject $AcquireTokenParameters -ErrorAction Stop
	    }
	}
    }
    finally {
	if (!$taskAuthenticationResult.IsCompleted) {
	    Write-Debug ('Canceling Token Acquisition for Application with ClientId [{0}]' -f $ClientApplication.ClientId)
	    $tokenSource.Cancel()
	}
	$tokenSource.Dispose()
    }

    ## Parse task results
    if ($taskAuthenticationResult.IsFaulted) {
	Write-Error -Exception $taskAuthenticationResult.Exception -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AcquireTokenParameters -ErrorAction Stop
    }
    if ($taskAuthenticationResult.IsCanceled) {
	Write-Error -Exception (New-Object System.Threading.Tasks.TaskCanceledException $taskAuthenticationResult) -Category ([System.Management.Automation.ErrorCategory]::OperationStopped) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationStopped' -TargetObject $AcquireTokenParameters -ErrorAction Stop
    }
    else {
	$AuthenticationResult = $taskAuthenticationResult.Result
    }
}
catch {
    Write-Error -Exception (Coalesce $_.Exception.InnerException,$_.Exception) -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AcquireTokenParameters -ErrorAction Stop
}
 
write-host $AuthenticationResult
write-host "Token is " $AuthenticationResult.AccessToken

# Setup API headers
$jwt = $AuthenticationResult.AccessToken
$headers = @{
    Authorization = "Bearer $jwt"
    Accept = "application/json; odata=nometadata"
}
$jsonheaders = ($headers | ConvertTo-Json)
write-host "headers are $jsonheaders"
write-host "headers are $headers"
$url = "https://$tenant-admin.sharepoint.com/_api/Web/CurrentUser"
write-host "url is: $url"

# Call the Sharepoint REST API
$resp = Invoke-RestMethod -Method 'GET' -Uri $url -Headers $headers
$resp
