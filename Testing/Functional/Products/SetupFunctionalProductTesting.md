# Setup Testing

In order to run the functional tests, the following items need to be setup.

## Windows

This testing needs to be run on a Windows computer or VM.

## Credentials

Two things are needed in order to authenticate to the various services that are being tested.  The first is a personal certificate.  Ask onboarding coordinator for the documentation on how to create a ScubaGear personal certificate.  Follow the instructions and note the value of the thumbprint.

The second is to add your certificate to the service principal.  Send the certificate and the thumbprint to the onboarding coordinator, and he will add it to the service principal and provide the id (aka the App ID).

## Powershell 5.1

ScubaGear runs on Powershell 5.1.  To run this version in Windows 10, search for "powershell" (not "pwsh"), and run it as administrator.  Run all commands in this shell.

## Pester

"Pester is a testing and mocking framework for PowerShell." ([Pester Quick Start](https://pester.dev/docs/quick-start))

Install an updated Pester module by running this command as administrator:

```
Install-Module -Name Pester -Force -SkipPublisherCheck
```

## Selenium

"Selenium is an open source umbrella project for a range of tools and libraries aimed at supporting browser automation." ([Wikipedia](https://en.wikipedia.org/wiki/Selenium_(software)))

Install Selenium by running this script in the repo:

```
./Testing/Functional/SmokeTest/UpdateSelenium.ps1
```
