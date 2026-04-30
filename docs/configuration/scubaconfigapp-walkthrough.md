# SCuBAGear Configuration Editor — Step-by-Step Walkthrough

This guide walks you through every step of creating a ScubaGear configuration file using the SCuBAGear Configuration Editor (ScubaConfigApp), from launching the application to saving your final YAML.

---

## Before You Begin

- ScubaGear must be installed. Run `Initialize-SCuBA` if you haven't already.
- You must have PowerShell 5.1 or later on a Windows machine with a graphical desktop.
- To use **Graph-assisted lookups** (auto-populate users and groups), launch with `-Online`. The signed-in account must have the following Microsoft Graph **delegated** permissions:

  | Permission | Used for |
  |------------|---------|
  | `User.Read.All` | Browse and resolve users when filling exclusion fields |
  | `Group.Read.All` | Browse and resolve groups when filling exclusion fields |
  | `Organization.Read.All` | Read tenant information |
  | `Application.Read.All` | Browse registered applications when filling the App ID field in Advanced Settings |

  These are delegated (user-context) permissions. The account you sign in with must be granted consent for all four, either via admin consent or user consent. A **Global Reader** role is typically sufficient for read access.

- To use **Run ScubaGear** from within the app, you must configure Application Authentication (non-interactive mode) — see [Step 7](#step-7-configure-advanced-settings).

---

## Step 1 — Launch the Application

Open a PowerShell window and run:

```powershell
Import-Module ScubaGear
Start-SCuBAConfigApp
```

> **Tip:** To pre-load an existing YAML configuration, pass it on launch:
> ```powershell
> Start-SCuBAConfigApp -ConfigFilePath "C:\configs\myconfig.yaml"
> ```

The application window opens. The **Main** tab is active by default.

---

## Step 2 — Fill In the Main Tab

The **Main** tab collects organization information and product selection. It must be completed before other tabs become usable.

### 2a. Organization Information

| Field | Required | Description |
|-------|----------|-------------|
| Tenant Domain | **Yes** | Your M365 tenant domain, e.g. `contoso.onmicrosoft.com` |
| Organization Name | **Yes** (BOD submissions) | Human-readable org name, e.g. `Department of Example` |
| Org Unit Name | No | Sub-unit, e.g. `Office of IT` |
| Description | No | Free-text note about this configuration |

1. Click the **Tenant Domain** field and type your domain. The field validates the format in real time — a red border indicates an invalid format.
2. Fill in **Organization Name**.
3. Fill in optional fields as needed.

### 2b. Select M365 Environment

Click the **M365 Environment** dropdown and select one:

- **Commercial** — standard public tenants
- **Government Community Cloud (GCC)**
- **Government Community Cloud High (GCC High)**
- **Department of Defense (DoD)**

### 2c. Select Products

Check at least one product under **Select at least one product**:

- Microsoft Entra ID (AAD)
- Defender
- Exchange Online (EXO)
- Power BI
- Power Platform
- SharePoint & OneDrive
- Microsoft Teams
- Defender Security Suite

> **At least one product must be selected.** Checking a product immediately enables that product's sub-tabs in the Exclusions, Annotate Policies, and Omit Policies tabs.

---

## Step 3 — Configure Exclusions

Navigate to the **Exclusions** tab.

Exclusions tell ScubaGear to skip specific users, groups, or domains when evaluating a policy. Only products that support exclusions will appear as sub-tabs (e.g., AAD, Defender, EXO, Defender Security Suite).

### 3a. Navigate to the Right Product Sub-Tab

Click the sub-tab for the product you want to configure (e.g., **AAD**, **DEFENDER**).

### 3b. Find the Policy

Use the **search box** at the top to filter by policy name or ID, or use the **criticality** and **configuration status** dropdowns to narrow results.

### 3c. Add an Exclusion

1. Locate the policy card.
2. Click the **exclusion type** dropdown on the card (e.g., *Conditional Access Policy Excluded Groups, Users…*) and select the exclusion type.
3. Fill in the fields (GUIDs, email addresses, domains, etc.).
   - If connected with `-Online`, click the **browse** icon next to a field to search users or groups from your tenant via Microsoft Graph.
4. Click **Save Exclusion**.

### 3d. Look for the Green Dot ✅

After saving, a **green dot** appears on the policy card header. This confirms the exclusion was saved to the in-memory configuration.

> **Yellow dot** = unsaved changes are pending. Always click **Save Exclusion** before moving to another policy or tab — unsaved data is lost on navigation.

> **No dot** = no exclusion configured for this policy.

### 3e. Repeat for Other Products

Switch to other product sub-tabs (e.g., **EXO**, **SECURITYSUITE**) and repeat.

---

## Step 4 — Configure Annotations

Navigate to the **Annotate Policies** tab.

Annotations add comments and flags to individual policies — for example, marking a result as an incorrect result (false positive) or noting a planned remediation date.

### 4a. Find the Policy

All products you selected appear as sub-tabs. Click the product sub-tab, then use search/filter to find the policy.

### 4b. Add an Annotation

1. Locate the policy card.
2. Check **Incorrect Result (False Positive)** if the assessment result is wrong.
3. Enter a **Comment** explaining the annotation. This is required if you mark the result incorrect.
4. Optionally set a **Remediation Date** (the date you expect the issue to be resolved).
5. Click **Save Annotate**.

### 4c. Look for the Green Dot ✅

A **green dot** confirms the annotation is saved. A **yellow dot** means you have unsaved changes — click **Save Annotate** before leaving.

> [!CAUTION]
> Marking a policy as an incorrect result can mask genuine compliance gaps. Only do this when you are certain the result is a false positive and document the justification in the Comment field.

---

## Step 5 — Configure Omissions

Navigate to the **Omit Policies** tab.

Omissions exclude a policy entirely from the assessment output — for example, if a policy is not applicable to your organization.

### 5a. Find the Policy

Click the product sub-tab, then use search/filter.

### 5b. Add an Omission

1. Locate the policy card.
2. Enter a **Rationale** explaining why this policy is being omitted. This field is required.
3. Optionally set an **Expiration Date** — after this date, the omission will no longer apply and the policy re-enters the assessment.
4. Click **Save Omit**.

### 5c. Look for the Green Dot ✅

Same indicator as Exclusions and Annotations — green dot = saved, yellow dot = unsaved pending changes.

> [!CAUTION]
> Omitting policies can introduce blind spots. Provide clear justification and always set an expiration date.

---

## Step 6 — Configure Global Settings *(optional)*

Navigate to the **Global Settings** tab.

These settings apply across all products and assessments:

| Setting | Description |
|---------|-------------|
| Preferred DNS Resolvers | IP addresses of DNS resolvers for SPF/DKIM/DMARC lookups |
| Skip DNS over HTTPS (DoH) | Check to disable DoH retry for failed DNS queries |

1. Expand the **Global Settings** section using the toggle.
2. Fill in any applicable values.
3. Click **Save** on the card.

---

## Step 7 — Configure Advanced Settings *(required for Run ScubaGear)*

Navigate to the **Advanced** tab.

### 7a. Application Authentication *(required to Run ScubaGear from within the app)*

> Due to Windows Authentication Manager (WAM) changes, ScubaGear can no longer run interactively inside the app. **You must configure a service principal with a certificate.**

1. Enable the **Application Settings** toggle.
2. Enter your **Application (Client) ID** — the GUID of your registered ScubaGear service principal.
   - Click the browse icon to search registered applications from Microsoft Graph (requires `-Online`).
3. Enter the **Certificate Thumbprint** — the 40-character hex thumbprint of the certificate in your local personal store.
   - Click **Select Certificate** to browse your certificate store.

### 7b. Output Configuration *(optional)*

1. Enable the **Output Configuration** toggle.
2. Set **Output Path** to where ScubaGear should write results (default: current directory).
3. Adjust file name prefixes if needed.

### 7c. OPA Configuration *(optional)*

Only needed if your OPA binary is not in the default path.

### 7d. General Settings *(optional)*

- **Log In**: Keep checked to allow ScubaGear to authenticate during execution.
- **Disconnect on Exit**: Uncheck to remain connected after execution.

---

## Step 8 — Preview Your Configuration

Click the **Preview & Generate** button in the top-right toolbar.

> [!IMPORTANT]
> **Always click Preview & Generate after making any changes.** Clicking the Preview tab directly does not refresh the YAML — the button must be pressed to regenerate the output from your current in-memory configuration.

The app navigates to the **Preview** tab and displays your complete YAML configuration.

### Review the YAML

Check that:
- `Organization:` matches your tenant domain
- `ProductNames:` lists all selected products
- `Exclusions:` contains all saved exclusion entries under the correct product and policy IDs
- `AnnotatePolicy:` contains your annotation entries
- `OmitPolicy:` contains your omission entries
- Advanced settings appear if configured

### Make Corrections

If anything looks wrong:
1. Navigate back to the relevant tab (Main, Exclusions, Annotate Policies, etc.)
2. Make your change and **click Save** on the card — watch for the **green dot** confirming the save
3. Return and click **Preview & Generate** again to refresh the YAML

---

## Step 9 — Save the YAML File

In the **Preview** tab:

1. Click **Save YAML** to write the file to disk. A file picker dialog opens.
2. Choose a location and file name (default is based on your tenant domain).
3. Click **Save**.

A success message confirms the file was saved.

> **Tip:** Click **Copy to Clipboard** to paste the YAML into another tool or editor without saving to a file.

---

## Step 10 — Run ScubaGear from the App *(optional)*

Navigate to the **Run ScubaGear** tab.

> **Prerequisite:** Application Authentication must be configured (see [Step 7a](#7a-application-authentication-required-to-run-scubagear-from-within-the-app)). The **Run ScubaGear** button will be disabled with an explanatory message if credentials are missing.

### 10a. Review Pre-Run Settings

Optionally adjust:

- **Silence BOD Warnings** — suppress Binding Operational Directive warnings in output
- **Dark Mode** — generate the HTML report in dark mode
- **Quiet Mode** — suppress the report from opening automatically
- **UUID Truncation** — control how much of UUIDs are shown in report file names

### 10b. Start the Assessment

1. Verify the status bar shows a green **Ready** message.
2. Click **Run ScubaGear**.
3. A progress window appears with real-time output from ScubaGear.
4. Wait for completion — assessments typically take 5–15 minutes depending on tenant size and number of products selected.

### 10c. Stop an In-Progress Run

Click **Stop** to cancel execution. Partial results may be available.

---

## Step 11 — Review Results

After execution completes, the app automatically navigates to the **Report Summary** tab.

### Reading the Report

Each assessed product appears as its own sub-tab. Within each tab:

| Column | Description |
|--------|-------------|
| Control ID | The policy identifier (e.g., `MS.AAD.1.1v1`) |
| Requirement | The policy requirement text |
| Result | Pass / Fail / Warning / Manual / Error |
| Criticality | SHALL or SHOULD |
| Details | Specific findings from the assessment |

### Status Indicators

| Color | Meaning |
|-------|---------|
| 🟢 Green | Pass — meets compliance requirements |
| 🔴 Red | Fail — does not meet requirements |
| 🟡 Yellow | Warning — needs attention |
| 🔵 Blue | Manual — requires human review |
| ⚫ Gray | Error or Not Applicable |

### Taking Action

For each failing or warning policy:
1. Note the **Control ID** and **Details** text.
2. Follow the remediation guidance in the [ScubaGear baselines documentation](../../PowerShell/ScubaGear/baselines/).
3. After remediation, run ScubaGear again (Step 10) to confirm the fix.

---

## Indicator Reference

| Indicator | Location | Meaning |
|-----------|----------|---------|
| 🟢 Green dot | Policy card header | Data is saved to the in-memory configuration |
| 🟡 Yellow dot | Policy card header | Unsaved changes — click **Save** before leaving |
| No dot | Policy card header | No data configured for this policy |
| Green status bar | Run ScubaGear tab | Ready to run — all required fields are set |
| Red status bar | Run ScubaGear tab | Cannot run — check the message for what is missing |

---

## Common Mistakes

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| Navigating away with a yellow dot | Your exclusion/annotation/omission is lost | Click **Save** before changing tabs |
| Clicking the Preview tab without pressing **Preview & Generate** | Stale YAML is displayed | Always click the **Preview & Generate** button |
| Not enabling Application Settings before running | Run ScubaGear button stays disabled | Configure App ID and Certificate Thumbprint in Advanced tab |
| Setting an expiration date in the past for omissions | Policy re-enters assessment immediately | Use a future date or leave blank for permanent omission |

---

## Using an Existing Configuration

To load and modify a previously saved YAML:

```powershell
Start-SCuBAConfigApp -ConfigFilePath "C:\configs\contoso.onmicrosoft.com.yaml"
```

The app pre-populates all fields from the file. Make your changes, then follow Steps 8–9 to regenerate and save.

---

## Related Documentation

- [Configuration File Reference](configuration.md) — manual YAML format documentation
- [ScubaConfigApp Module Reference](scubaconfigapp.md) — function parameters and module overview
- [ScubaGear Execution](../execution/execution.md) — running ScubaGear from the command line
