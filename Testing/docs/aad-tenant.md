# Setup the Tenant for Functional Testing of AAD Conditional Access Policies

Numerous test cases in the AAD functional test plan associated with conditional access rely on some dependencies in the tenant that you must setup ahead of time:

- **Step 1** - Create a conditional access policy in the tenant named **Automated Test 1 - DO NOT MODIFY** and set it up as per the configuration in the screenshot below. Set the policy to **Report-only** (do NOT turn it on). This policy is downloaded from the tenant when the test orchestrator executes and its characteristics are modified in memory (using the test orchestrator's RunCached function) before the provider JSON is sent to the Rego. This CA policy must be configured exactly as shown below in order for the test cases to work correctly. The only purpose of this CA policy is to support the execution of the test plan - the policy serves no purpose to the actual operations of the tenant and hence why it must be set to Report-only.

![image](https://github.com/cisagov/ScubaGear/assets/107076927/ae19af14-c551-4ef1-b98b-e2e32087bcb8)

- **Step 2** - The following conditional access policies are also required to be created in the tenant and configure as per the respective AAD baseline policy instructions, including setting Enable Policy to **On**. The policy names in the tenant must be configure exactly as described below:
  - MS.AAD.1.1v1 Legacy authentication SHALL be blocked
  - MS.AAD.2.1v1 Users detected as high risk SHALL be blocked
  - MS.AAD.2.3v1 Sign-ins detected as high risk SHALL be blocked
  - MS.AAD.3.2v1 If phishing-resistant MFA has not been enforced, an alternative MFA method SHALL be enforced for all users
