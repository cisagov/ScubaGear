# ScubaGear Functional Testing Automation <!-- omit in toc --> #

This document outlines the ScubaGear software test automation and its usage. The document also contains instructions for adding new functional tests to existing automation suite.

## Table of Contents <!-- omit in toc --> ##

- [ScubaGear Functional Testing Automation ](#scubagear-functional-testing-automation-)
  - [Table of Contents ](#table-of-contents-)
  - [Functional Testing Prerequisites](#functional-testing-prerequisites)
    - [Windows System with Chrome](#windows-system-with-chrome)
    - [Pester](#pester)
    - [Selenium](#selenium)
    - [Service Principal Account](#service-principal-account)
  - [Functional Testing Structure](#functional-testing-structure)
    - [Functional test orchestrator](#functional-test-orchestrator)
    - [Product test plans](#product-test-plans)
  - [Functional Testing Usage](#functional-testing-usage)
    - [Test Usage Example](#test-usage-example)
  - [Adding New Functional Tests](#adding-new-functional-tests)
    - [Adding new functional test - Example #1](#adding-new-functional-test---example-1)
    - [Adding new functional test - Example #2](#adding-new-functional-test---example-2)
  - [Nightly Functional Tests](#nightly-functional-tests)
  - [Troubleshooting](#troubleshooting)
    - [Chrome browser version issue](#chrome-browser-version-issue)
    - [Service principal authentication issue](#service-principal-authentication-issue)

## Functional Testing Prerequisites ##

Running ScubaGear functional test automation require Windows compute or VM end system. This development system should be setup with Pester, Selenium, Chrome and PowerShell 5.1. The repository provides a few utility scripts to install and update these prerequisite components.

### Windows System with Chrome ###

Functional testing needs to be run on a Windows system with Chrome browser installed. Automation suite uses Selenium tool which requires Chrome driver for its web component testing.

### Pester ###

"Pester is a testing and mocking framework for PowerShell." ([Pester Quick Start](https://pester.dev/docs/quick-start))

On your Windows development system, install an updated Pester module by running following command as an administrator:

```
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Selenium ###

"Selenium is an open source umbrella project for a range of tools and libraries aimed at supporting browser automation." ([Wikipedia](https://en.wikipedia.org/wiki/Selenium_(software)))

On your Windows development system, Install Selenium by running following utility script provided in the repo:

```
./Testing/Functional/SmokeTest/UpdateSelenium.ps1
```

### Service Principal Account ###

Functional testing of ScubaGear can be executed in two modes: interactive mode using your personal tenant credentials, and service principal mode. ScubaGear developer and testing team members are provided with credentials for each test tenant which can be used for interactive mode testing. 

In addition, they should also setup to use the "ScubaGear Functional Test Orchestrator" service principal App.  To do this, provide your end-system certificate and thumbprint to the tenant Global Administrator. The Global Administrator will provide you with an AppID that would be needed in subsequent test execution steps. 

## Functional Testing Structure ##

ScubaGear functional testing suite has two main components: Orchestrator and Product test plans.

### Functional test orchestrator ### 

Functional test orchestrator (/Testing/Functional/Products/Products.tests.ps1) executes the tests using a predefined product test plan and various input test parameters as defined by the tester. These parameters are:

- Thumbprint of the certificate associated with functional testing service principal
- AppId associated with service principal and certificate
- Tenant Domain
- Tenant Display Name
- M365 Environment type (viz. gcc, gcchigh, commercial)
- An optional variant parameter

### Product test plans ###

Each of ScubaGear supported products should have one or more test plans. Each test plan is defined as a YAML file and consists of multiple test cases for each secure configuration policy. Test cases are defined for both non-complaint and complaint use cases. The objective of functional testing is to test every possible non-complaint/complaint configuration for a policy and ensure that ScubaGear is correctly identifying it as a policy failure/pass. 

Development team for each product are responsible for maintaining these test plans and ensure that they are accurate and complete. Note that each product has at least one test plan associated with it. There can be multiple test plans for a product - these additional test plans are used to capture unique configurations based on tenant type and/or powershell variant. To distinguish this, Test plans used the following naming convention:
```
product.<variant>.testplan.yaml
```
The optional variant can have values like: g5, e5, gcc, pnp, spo, e# etc. These 'variant' test plans capture test cases unique to that tenant type and/or powershell type. 



## Functional Testing Usage ##

Complete the functional testing prerequisites provided in an earlier section and have the test system setup for running functional test automation suite. Then define the Pester Test Container parameters provided in the "Data" definition as below:

```
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{  Thumbprint = "860E4A6E79BEE660E07440444AC9DBA690690B95"; TenantDomain = "MyE5Tenant.onmicrosoft.com"; TenantDisplayName = "MyE5Tenant"; AppId = "dbaaaaaa-1ff0-493f-be3d-03d9babcabcab"; ProductName = "aad"; M365Environment = "commercial" }
```
Define the values in -Data to match your tenant and service principal details. Also ensure that targeted product and M365 Environment type are correctly matched for the given tenant type. The above example will run the aad.testplan.yaml on the provided commercial tenant in the service principal mode. 

For testing AAD on a specific variant as well, provide the variant parameter in the -Data, as below:

```
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant = "g3"; Thumbprint = "860E4A6E79BEE660E07440444AC9DBA690690B95"; TenantDomain = "MyG3Tenant.onmicrosoft.com"; TenantDisplayName = "MyG3Tenant"; AppId = "dbaaaaaa-1ff0-493f-be3d-03d9babcabcab"; ProductName = "aad"; M365Environment = "gcc" }
```


### Test Usage Example

AAD functional testing in interactive mode with all-tenant YAML file:
```
$TestContainers = @()

$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ TenantDomain = "MyG5tenant.onmicrosoft.com"; TenantDisplayName = "My G5 tenant"; ProductName = "aad"; M365Environment = "gcc" }

$PesterConfig = @{
	Run = @{
		Container = $TestContainers
	}
	Output = @{
		Verbosity = 'Detailed'
	}
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig 

Invoke-Pester -Configuration $Config
```

AAD functional testing in interactive mode with G5 variant YAML file:

```
$TestContainers = @()

$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="g5"; TenantDomain = "MyG5tenant.onmicrosoft.com"; TenantDisplayName = "My G5 tenant"; ProductName = "aad"; M365Environment = "gcc" }

$PesterConfig = @{
	Run = @{
		Container = $TestContainers
	}
	Output = @{
		Verbosity = 'Detailed'
	}
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig 

Invoke-Pester -Configuration $Config

```

AAD functional testing in service principal mode by filtering specific test cases:
```
$TestContainers = @()

$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "D17F58D66DC5750EF78F25FF04CCE88DE730BCA6"; AppId = "1947b06c-46a9-4ff2-80c8-27261e58868b"; TenantDomain = "MyG5tenant.onmicrosoft.com"; TenantDisplayName = "My G5 tenant"; ProductName = "aad"; M365Environment = "gcc" }

$PesterConfig = @{
	Run = @{
		Container = $TestContainers
	}
  Filter = @{
	 	Tag = @("MS.AAD.2.1v1")
	}
	Output = @{
		Verbosity = 'Detailed'
	}
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig 

Invoke-Pester -Configuration $Config
```


## Adding New Functional Tests ##

Whenever there is a code change to ScubaGear - the development team should assess if the changes requires a new functional test. If so, test cases should be added to appropriate product test plan; if needed, add a new test plan. For code changes related to existing policies, if the update exposes additional configuration options - new test cases should be added for each new non-compliant and complaint configuration options. For code changes related to new policies or new features, test cases should be added for each possible non-complaint and complaint configuration option. The non-complaint test cases should be added first followed by the complaint test case. This is to ensure that at the end of the functional test run, the test tenant is left in a complaint state. See example section below for additional guidance. 

The checklist below should be used by the development team when it adds a new feature or updates an existing policy.  The goal of the list below is to ensure consistency of automated functional testing and overall quality of ScubaGear.

- [ ] Ensure all Non-Complaint configuration options for the affected policy are tested.
- [ ] Ensure all Complaint configuration options for the affected policy are tested.
- [ ] Ensure that any changes to HTML report output are tested.
- [ ] Validate that all new functional tests pass on CI for the branch before creating the PR


### Adding new functional test - Example #1 ###

Use case: functional test for a SCB where there is a single non-complaint configuration option and a single complaint configuration option.

Example SCB: MS.POWERPLATFORM.1.1v1 - the ability to create production and sandbox environments should be restricted to admin users

Configuration options: looking into the tenant, there are only two configurations options for restricting the ability to create production and sandbox environments. Non-complaint config: allowing everyone to create production and sandbox environments. Complaint config: restricting it only specific admins.

![Power Platform 1.1 Config](/images/PP-1-1.png)

Automated functional test case for non-complaint and complaint configs:
```
  - PolicyId: MS.POWERPLATFORM.1.1v1
    TestDriver: RunScuba
    Tests:
      - TestDescription: MS.POWERPLATFORM.1.1v1 Non-Compliant case - Allows production/sandbox environment creation by nonadmin users
        Preconditions:
          - Command: Set-TenantSettings
            Splat:
              RequestBody:
                DisableEnvironmentCreationByNonAdminUsers: false
        Postconditions: []
        ExpectedResult: false
      - TestDescription: MS.POWERPLATFORM.1.1v1 Compliant case - Restricts production/sandbox environment creation to admin users
        Preconditions:
          - Command: Set-TenantSettings
            Splat:
              RequestBody:
                DisableEnvironmentCreationByNonAdminUsers: true
        Postconditions: []
        ExpectedResult: true
```

### Adding new functional test - Example #2 ### 

Use case: functional test for a SCB where there are multiple non-complaint configuration options.

Example SCB: MS.TEAMS.1.3v1: restricting dial-in users and anonymous users from being admitted into a Teams meeting automatically.

Configuration options: looking into the tenant there are multiple options in allowing and restricting different groups of users to automatically admitted into a meeting. There are two config options that would fail the SCB and others that would pass the SCB.

![Teams 1.3 Config](/images/Teams-1-3.png)

Automated functional test case for non-complaint and complaint config options:

```
  - PolicyId: MS.TEAMS.1.3v1
    TestDriver: RunScuba
    Tests:
      - TestDescription: MS.TEAMS.1.3v1 Non-compliant - Dialin bypass lobby; Everyone is autoadmitted user
        Preconditions:
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              Identity: Global
              AllowPSTNUsersToBypassLobby: true
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              Identity: Global
              AutoAdmittedUsers: EveryOne
        Postconditions: []
        ExpectedResult: false
      - TestDescription: MS.TEAMS.1.3v1 Non-complaint - Dialin bypass lobby; Everyone not auto admitted user
        Preconditions:
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              Identity: Global
              AllowPSTNUsersToBypassLobby: true
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              AutoAdmittedUsers: EveryoneInCompany
              Identity: Global
        Postconditions: []
        ExpectedResult: false
      - TestDescription: MS.TEAMS.1.3v1 Compliant - Dialin not bypass lobby Everyone not auto admitted user
        Preconditions:
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              Identity: Global
              AllowPSTNUsersToBypassLobby: false
          - Command: Set-CsTeamsMeetingPolicy
            Splat:
              AutoAdmittedUsers: EveryoneInCompany
              Identity: Global
        Postconditions: []
        ExpectedResult: true
```

## Nightly Functional Tests ##

Product functional tests are being run for multiple product-tenant combinations. Development team should check the successful completion of these runs for any regressions. Currently the following "product / tenant / other variant" combinations are run by a cron job:
- AAD - G3
- AAD - G5
- AAD - E5
- Defender - G3
- Defender - G5
- EXO
- Power Platform
- SharePoint
- Teams

## Troubleshooting ##

### Chrome browser version issue ###

If the Chrome browser on your system has been updated since you setup the Selenium environment, you may receive an error message like below:

![Chrome browser version](/images/chrome-version.png)

To resolve this, first kill any ChromeDriver.exe processes running by using the Task Manager. If you do not successfully kill that process you might receive an error message such as the one below.

![Chrome browser processes](/images/chrome-process-kill.png)

Then execute the commands below to update the Selenium Chrome driver.

```
import-module Selenium

.\Testing\Functional\SmokeTest\UpdateSelenium.ps1
```

### Service principal authentication issue ###

If you are trying to run the test orchestrator as a service principal and your client certificate has NOT been uploaded into the Azure AD registered applications Certificates and Secrets page, you may receive an error similar to the one below (this is specific to the AAD product - other products may give slightly different errors). Contact the system admin to upload your certificate file.

![service-principal-error](/images/service-principal.png)

