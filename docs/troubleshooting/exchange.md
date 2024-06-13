# Exchange Online

When running ScubaGear against Exchange Online, you may see an error about the maximum number of connections in the PowerShell window:

> New-ExoPSSession : Processing data from remote server outlook.office365.com failed with the following error message: [AuthZRequestId=8feccdea-493c-4c12-85dd-d185232cc0be][FailureCategory=A uthZ-AuthorizationException] Fail to create a runspace because you have exceeded the maximum number of connections allowed : 3

If you see this error message, run the following command, which will delete the tokens used  for Exchange:

```powershell
# Delete Exchange tokens
Disconnect-ExchangeOnline
```

Alternatively, run the following command, which will delete all tokens that ScubaGear has used:

```powershell
# Delete all tokens
Disconnect-SCuBATenant
```
