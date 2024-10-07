# Description of ThomMSALResearch folder

## Installation dllsetup.ps1

Run the dllsetup.ps1 script to setup the environment before executing any of the other scripts. This script fetches nuget.exe and downloads the following packages: Microsoft.Identity.Client, Microsoft.Identity.Client.Desktop, Microsoft.Web.WebView2. Then based on the currently running version of Powershell, the script calls Add-Type to load the appropriate .NET assembly dll from the downloaded package files into the current powershell session. Presumably, once you have downloaded the dependency files, you don't need to download them again so the download part should probably be ripped into its own separate script apart from the dll load functionality.

## msal-lib-interactive-auth.ps1

This script calls the .NET MSAL AcquireTokenInteractive method to create a popup window that take the user through the interactive process of performing their login with user/pass/MFA and acquiring the authentication token from the Microsoft login API. Then it pull s the acquired token and passes it to an API call in a Sharepoint REST method.

## api-client.ps1

This script contains a custom class named Msal which encapulates the functionality in the interactive auth script described in the previous bullet in a method named GetTokenInteractive. It also contains a method named GetTokenCertificate which was designed to work with service principal authentication using client certificates (GetTokenCertificate is unfinished). There is also a custom class named ApiClient that contains a method named Request which ScubaGear could use to call Sharepoint or other back-end M365 REST APIs that accept Microsoft authentication tokens. There is also some test code at the bottom of the script which demonstrates how to use these custom classes.
