# ScubaGear Functional Testing Automation <!-- omit in toc --> 
ScubaGear repository consists of an automation suite to help test the functionality of the ScubaGear tool itself. The test automation is geared towards contributors who want to execute functional test orchestrator as part of their development/testing activity.

This README outlines the ScubaGear software test automation and its usage. The document also contains instructions for adding new functional tests to existing automation suite.

## Table of Contents <!-- omit in toc --> 

- [Functional Testing Prerequisites](#functional-testing-prerequisites)
  - [Windows System with Chrome](#windows-system-with-chrome)
  - [Pester](#pester)
  - [Selenium](#selenium)
  - [Service Principal Account](#service-principal-account)
    - [Generating client certificate on the test system](#generating-client-certificate-on-the-test-system)
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
  - [Issues with installing Pester](#issues-with-installing-pester)
  - [Iusses with Selenium](#iusses-with-selenium)
  - [Chrome browser version issue](#chrome-browser-version-issue)
  - [Service principal authentication issue](#service-principal-authentication-issue)
  - [Additional resources for admins](#additional-resources-for-admins)

## Functional Testing Prerequisites ##

Running the ScubaGear functional test automation requires a Windows computer or VM. This development system should be setup with Pester, Selenium, Chrome and PowerShell 5. The repository provides a few utility scripts to install and update these prerequisite components.

### Windows System with Chrome ###

Functional testing needs to be run on a Windows system with the Chrome browser installed. The automation suite uses Selenium, which requires the Chrome driver for its web component testing.

### Pester ###

"Pester is a testing and mocking framework for PowerShell." ([Pester Quick Start](https://pester.dev/docs/quick-start))

On your Windows development system, install an updated Pester module by running the following command from the root of the ScubaGear directory (viz. C:\UserN\ScubaGear\\):

```
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Selenium ###

"Selenium is an open source umbrella project for a range of tools and libraries aimed at supporting browser automation." ([Wikipedia](https://en.wikipedia.org/wiki/Selenium_(software)))

On your Windows development system, install Selenium by running:
```
Install-Module Selenium
```
Automation also needs to update Selenium and install latest Chrome driver, to do that, run the following utility script provided in the repo:

```
./Testing/Functional/SmokeTest/UpdateSelenium.ps1
```

### Service Principal Account ###

Functional testing of ScubaGear can be executed in two modes: interactive mode, using your personal tenant credentials, and non-interactive mode, using a service principal and certificate thumbprint. ScubaGear developer and testing team members are provided with credentials for each test tenant that can be used for interactive mode testing. 

In addition, they should also be setup to use the "ScubaGear Functional Test Orchestrator" service principal app.  To do this, provide your end-system certificate and thumbprint to the tenant Global Administrator. The Global Administrator will provide you with an AppID that will be needed in subsequent test execution steps. 

#### Generating client certificate on the test system
In order to use functional testing service principal, your test system need to be setup with a client certificate. Use the following powershell script to generate client certificate:
```
$CertName = "ScubaServicePrincipal"
$CertParams = @{
    Subject = $CertName
    KeySpec = "KeyExchange"
    CertStoreLocation = "Cert:\CurrentUser\My"
}

$MyCert = New-SelfSignedCertificate @CertParams
Write-Output $MyCert


########## Exporting the cert public key (this is so you can upload the file to the Azure AD application as a credential)
Export-Certificate -Cert $MyCert -Type CERT -FilePath .\ScubaServicePrincipal.cer
```
Once the certificate is created, provide it to the tenant administrator to align it with functional testing application. 

## Functional Testing Structure ##

ScubaGear functional testing suite has two main components: the orchestrator and product test plans.

### Functional test orchestrator ### 

Functional test orchestrator (`/Testing/Functional/Products/Products.tests.ps1`) executes the tests using a predefined product test plan and various input test parameters as defined by the tester. These parameters are:

- Thumbprint of the certificate associated with functional testing service principal
- AppId associated with service principal and certificate
- Tenant Domain
- Tenant Display Name
- M365 Environment type (viz. `gcc`, `gcchigh`, `commercial`)
- An optional variant parameter

### Product test plans ###

Each of the ScubaGear supported products should have one or more test plans. Each test plan is defined by a YAML file and consists of multiple test cases for each secure configuration policy. Test cases are defined for both non-compliant and compliant use cases. The objective of functional testing is to test every possible non-compliant/compliant configuration for a policy and ensure that ScubaGear is correctly identifying it as a policy failure/pass. 

The development teams for each product are responsible for maintaining these test plans and ensuring that they are accurate and complete. Note that each product has at least one test plan associated with it. There can be multiple test plans for a product; these additional test plans are used to capture unique configurations based on tenant type and/or PowerShell variant. To differentiate among the test plans, they use the following naming convention:
```
product.<variant>.testplan.yaml
```
The optional variant can have values like: `g5`, `e5`, `gcc`, `pnp`, `spo`, `e#` etc. These `variant` test plans capture test cases unique to that tenant type and/or powershell type. 



## Functional Testing Usage ##

After setting up the prerequisites, define the Pester test container parameters in a test execution utility script called "RunFunctionalTest.ps1" as shown below: 


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
Copy the above utility script and save it into a file named "RunFunctionalTest.ps1" on your system. Save this file in a folder named FunctionalTesting that is at the same level in your directory tree as ScubaGear as shown below.
![Functional testing folder location](/images/FunctionalTestingFolder.png)


The main construct of the RunFunctionalTest.ps1 script is the Pester Test Container. For your specific testing, define the Pester Test Container parameters provided in the `Data` definition as below:

```
$TestContainers += New-PesterContainer 
  -Path "Testing/Functional/Products" -Data @{  Variant ="g3"; Thumbprint = "860E4A6E79BEE660E07440444AC9DBA690690B95"; TenantDomain = "MyE5Tenant.onmicrosoft.com"; TenantDisplayName = "MyE5Tenant"; AppId = "dbaaaaaa-1ff0-493f-be3d-03d9babcabcab"; ProductName = "aad"; M365Environment = "commercial" }
```
To customize your functional testing, define the values for various parameters in `-Data` using following parameter definitions and explanations:
- Thumbprint: this parameter is required to use the functional test orchestrator in service principal mode. The value should match the thumbprint of a local client certificate installed on your test machine. If there is no Thumbprint parameter value in the execution file, tests will be run in interactive mode.  
- TenantDomain: FQDN of the test tenant. Modify the TenantDomain value based on test domain (viz. `MyTenant.onmicrosoft.com`).
- TenantDisplayName: The display name tag of the tenant. Modify the TenantDisplayName value to the display name of your target tenant (refer to the Scuba M365 Tenants Metadata.docx file in Slack)
- AppID: The Application ID of the service principal obtained from the test tenant. The AAD application portal will have this unique application id for the functional testing service principal.
- ProductName: Name of the ScubaGear product that is being tested for functionality. Modify the ProductName value to the desired product (Viz. `aad`, `exo`, `teams` etc.)
- M365Environment: The M365Environment variable: `commercial`, `gcc`, `gcchigh` etc.- refer to the ScubaGear README for all possible values. Ensure that targeted M365 Environment type is correctly matched for the given test tenant. 
- (Optionsal) Variant: For testing the ScubaGear product on a specific variant, provide the variant parameter. Ensure that this optional parameter value matches with product's test plans. For example AAD product has a g3 tenant specific test plan named as `aad.g3.testplan`. By providing the `g3` value for the variant, you can run the g3 specific test plan in addition to the default AAD test plan. 




### Test Usage Example

AAD functional testing:

Here are the instructions for running the functional test orchestrator with the AAD test plan YAML files.


Note: Several of the test cases in the AAD functional test plan associated with conditional access rely on some dependencies in the tenant that you must setup ahead of time. Tenant global administrator should be able to set this up.

AAD product has three test plans using respective YAML files
- All tenants - You will execute the `aad.testplan.yaml` tests against all tenants regardless of tenant type.
- G5/E5 tenants - You will also execute the `aad.g5.testplan.yaml` but only if the tenant is G5/E5.
- G3/E3 tenants - You will also execute the `aad.g3.testplan.yaml` but only if the tenant is G3/E3.



Use the following example execution script to run AAD product testing in interactive mode with all-tenant YAML file:
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

Use the following example execution script to run AAD functional testing in interactive mode with G5 variant YAML file:

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

AAD functional testing for specific test cases: when developing or if you are testing pull requests you may need to execute just a single baseline policy in the respective YAML test plan file. To do that you will add Pester filter tags to the PesterConfig parameter. 

Use the following example execution script to run a test against AAD policy MS.AAD.2.1v1 using a service principal. 
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

Whenever there is a code change to ScubaGear, the development team should assess if the changes require a new functional test. If so, test cases should be added to the appropriate product test plan; if necessary, a new test plan should be added. For code changes related to existing policies, if the update exposes additional configuration options, then new test cases should be added for each new non-compliant and compliant configuration options. For code changes related to new policies or new features, test cases should be added for each possible non-compliant and compliant configuration option. The non-compliant test cases should be added first followed by the compliant test case. This is to ensure that at the end of the functional test run, the test tenant is left in a compliant state. See the example section below for additional guidance. 

The checklist below should be used by the development team when it adds a new feature or updates an existing policy.  The goal of the list below is to ensure consistency of automated functional testing and overall quality of ScubaGear.

- [ ] Ensure that all non-compliant configuration options for the affected policy are tested.
- [ ] Ensure that all compliant configuration options for the affected policy are tested.
- [ ] Ensure that all `Not Applicable` test cases for the affected policy are tested.
- [ ] Validate that all new functional tests pass against the feature branch before creating the PR (developers can potentially use GitHub functional test actions to run against their branch).


### Adding new functional test - Example #1 ###

**Use case**: Functional test for an SCB where there is a single non-compliant configuration option and a single compliant configuration option.

**Example SCB**: MS.POWERPLATFORM.1.1v1 - The ability to create production and sandbox environments should be restricted to admin users.

**Configuration options**: Looking into the tenant, there are only two configurations options for restricting the ability to create production and sandbox environments. 
- Non-compliant config: allowing everyone to create production and sandbox environments. 
- Compliant config: restricting it only specific admins.

![Power Platform 1.1 Config](/images/PP-1-1.png)

This is an automated functional test case for both non-compliant and compliant configs:
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

**Use case**: Functional test for a SCB where there are multiple non-complaint configuration options.

**Example SCB**: MS.TEAMS.1.3v1: Restricting dial-in users and anonymous users from being admitted into a Teams meeting automatically.

**Configuration options**: Looking into the tenant there are multiple options in allowing and restricting different groups of users to automatically admitted into a meeting. There are two config options that would fail the SCB and others that would pass the SCB.

![Teams 1.3 Config](/images/Teams-1-3.png)

This is an automated functional test case for non-compliant and compliant config options:

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
      - TestDescription: MS.TEAMS.1.3v1 Non-compliant - Dialin bypass lobby; Everyone not auto admitted user
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

A GitHub workflow is used to execute multiple product functional tests every night, and they are being run for multiple product-tenant combinations. Development teams should work with operational team to debug any issues found during nightly and/or weekly functional tests. The current list of tests can be found in a Slack canvas. 

## Troubleshooting ##

### Issues with installing Pester
If the Pester module is pre-installed and pre-loaded on your system, you may see following message when you attempt to install it:

```
WARNING: The version '5.5.0' of module 'Pester' is currently in use. Retry the operation after closing the
applications.
```

To Resolve above issue, try the following:
- Close the PowerShell session
- Open Task Manager to find any background instances of PowerShell and close them all 
- Uninstall all versions of Pester using following command
  ```
  Uninstall-Module -Name Pester -Force -AllVersions
  ```  
- The above commands should uninstall previous versions of Pester. Now open a new PowerShell window to install Pester.
- If you continue to see issues with Pester installation, use the following command to find the location of previously installed version of Pester and remove it by other means.
  ```
  (GetInstalledModule -Name Pester).InstalledLocation
  ```
- Best practice is to install Pester and other modules as a non-admin user with either 'Current User' or 'AllUsers' scope. When modules are installed with 'AllUsers' scope, they are installed to the ``` $env:ProgramFiles\PowerShell\Modules``` location. The 'CurrentUser' scope installs modules to ``` $HOME\Documents\PowerShell\Modules``` location. 

### Iusses with Selenium
We have seen issues with Selenium where test orchestrator would not run and produce random errors. If you have seen issues where error messages does not match with any other items in this troubleshooting section, try uninstalling and re-installing Selenium using following commands:
```
uninstall-module Selenium
install-module Selenium
./Testing/Functional/SmokeTest/UpdateSelenium.ps1
```



### Chrome browser version issue ###

If the Chrome browser on your system has been updated since you setup the Selenium environment, you may receive an error message like below:

![Chrome browser version](/images/chrome-version.png)

To resolve this, first kill any ChromeDriver.exe processes running by using the Task Manager. Note that ChromeDriver.exe processes can be hidden under the PowerShell app process and may not be visible in the main process list of Task Manager. Expand PowerShell app processes as shown in the image below to check for any hidden ChromeDriver processes, and if you find any, kill them all.

![Chrome browser processes](/images/chrome-process-kill2.png)

If you do not successfully kill that process you might receive an error message such as the one below.

![Chrome browser processes](/images/chrome-process-kill.png)


Execute the commands below to update the Selenium and Chrome driver.

```
.\Testing\Functional\SmokeTest\UpdateSelenium.ps1
```
Sometimes the UpdateSelenium script has a problem getting rid of an older chromedriver.exe, even if you think you have killed any running processes named 'chromedriver.exe'. You might receive the error `Cannot remove item. Access to the path ...\chromedriver.exe is denied`, as shown in the screenshot above. In that case, you should follow the steps below:

- Open the path shown in the error message in Explorer (e.g. `C:\Users\username\Documents\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies`)
- Rename the file to chromedriver.exe.bak
- Check the running processes in Task Manager for instances of a process named "chromedriver.exe.bak" and kill any that are shown
- Delete the file chromedriver.exe.bak from the drive
- Run the UpdateSelenium script again


### Service principal authentication issue ###

If you are trying to run the test orchestrator as a service principal and your client certificate has NOT been uploaded into the Azure AD registered applications Certificates and Secrets page, you may receive an error similar to the one below (this is specific to the AAD product; other products may give slightly different errors). Contact the system admin to upload your certificate file.

![service-principal-error](/images/service-principal.png)

### Additional resources for admins
The following resources are for M365 tenant admins to provide additional information on setting up the infrastructure (service principals, user provisioning, etc.) for functional testing of ScubaGear. 

- [How to setup the permissions required to execute the automated functional test orchestrator](https://github.com/cisagov/ScubaGear/issues/589)

- [How to setup a tenant with the necessary AAD conditional access policies to run the Automated Functional Test Orchestrator](https://github.com/cisagov/ScubaGear/issues/591) 

