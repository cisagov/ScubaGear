# Download from GitHub

The recommended way to install ScubaGear is from [PSGallery](psgallery.md), but it can also be downloaded from GitHub:

1. Go to the [releases page](https://github.com/cisagov/ScubaGear/releases) and find the latest release.
2. Under the `Assets` header, click `ScubaGear-v1-3-0.zip`to download the zip file.
3. Extract the zip file into the folder of your choice.

Once ScubaGear has been downloaded, the required [dependencies](../prerequisites/dependencies.md) can be installed.

## PowerShell Execution Policy

PowerShell has a feature known as an execution policy that can prevent ScubaGear from running when it is downloaded from Github.

>"PowerShell's [execution policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1) is a safety feature that controls the conditions under which PowerShell loads configuration files and runs scripts. This feature helps prevent the execution of malicious scripts."  

## Execution Policy on Windows 

On **Windows servers**, the default execution policy is `RemoteSigned`, which allows ScubaGear to run after the publisher (CISA) is agreed to once. ScubaGear is signed by a commonly-trusted Certificate Authority (CA). 

On **Windows clients**, the default execution policy is `Restricted`. This policy can prevent ScubaGear from running because it (correctly) considers parts of ScubaGear to be scripts.  

## Execution Policy Changes

To see the current execution policy, run this cmdlet:

```powershell
# Get execution policy for current PowerShell session
Get-ExecutionPolicy
```

More information can be found in [Microsoft's documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-executionpolicy?view=powershell-5.1).

If the execution policy is not `RemoteSigned`, it can be changed for the local computer using this cmdlet:

```powershell
# Set execution policy to Remote Signed
Set-ExecutionPolicy `
  -ExecutionPolicy RemoteSigned `
  -Scope LocalMachine
```

More information can be found in [Microsoft's documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-5.1).

> **Note**: If your execution policy is set to `Restricted` and you cannot change it, then you will not be able to run ScubaGear.

## Mark of the Web

**Windows clients** with an execution policy of `Unrestricted` generate a warning about running untrusted scripts when executing ScubaGear, even when the scripts and modules are signed, because the files contain an identifier showing that they were downloaded from the Internet. This identifier, informally referred to as a [mark of the web](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.4#manage-signed-and-unsigned-scripts), can be removed by running `Unblock-File` on the scripts and modules in the ScubaGear folder. 


```powershell
# Run these commands one at a time in the ScubaGear folder
# to unblock PowerShell files
Get-ChildItem *.ps1 -Recurse | Unblock-File
Get-ChildItem *.psm1 -Recurse | Unblock-File
Get-ChildItem *.psd1 -Recurse | Unblock-File
```

> **Warning**: Users should use `Unblock-File` carefully and only run it on files they have vetted and deem trustworthy to execute on their system. See Microsoft's documentation on [unblocking files](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-5.1) for more information.
