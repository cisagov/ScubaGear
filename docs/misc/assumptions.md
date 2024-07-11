# Assumptions

## M365 Product License Assumption

ScubaGear has been tested against tenants that have an M365 E3 or G3 and E5 or G5 license bundle. It may still function for tenants that do not have one of these bundles.

Some of the policy checks in the baseline rely on the following licenses which are included by default in M365 E5 and G5.

* Microsoft Entra ID P2
* Microsoft Defender for Office 365 Plan 1

If a tenant does not have the licenses listed above, the report will display a non-compliant output for those policies.

> **Note**: DOD endpoints are included, but have not been tested. Please open an issue if you encounter bugs.