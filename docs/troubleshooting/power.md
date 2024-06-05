# Power Platform

In order for ScubaGear to properly assess Power Platform, one of the following conditions must be met:

- The tenant must include the `Power Apps for Office 365` license and the user running the tool must have the `Power Platform Administrator` role, or...
- The user running the tool must have the `Global Administrator` role.

In addition to those conditions, the correct [M365Environment parameter](../configuration/parameters.md#m365environment) value must be used with `Invoke-SCuBA`:

If any of these conditions are not met, an error will be thrown similar to the one shown below:

>Invoke-ProviderList : Error with the PowerPlatform Provider. See the exception message for more details: "Power Platform Provider ERROR: The M365Environment parameter value is not set correctly which WILL cause the Power Platform report to display incorrect values.

> M365Environment Parameter value: commercial  
Your tenant's OpenId-Configuration: tenant_region_scope: NA, tenant_region_sub_scope: GCC   

>Rerun ScubaGear with the correct M365Environment parameter value by looking at your tenant's OpenId-Configuration displayed above and contrast it with the mapped values in the table below  
M365Environment => OpenId-Configuration  
commercial: tenant_region_scope:NA, tenant_region_sub_scope:  
gcc: tenant_region_scope:NA, tenant_region_sub_scope: GCC  
gcchigh : tenant_region_scope:USGov, tenant_region_sub_scope: DODCON  
dod: tenant_region_scope:USGov, tenant_region_sub_scope: DOD  
Example Rerun for gcc tenants: Invoke-Scuba -M365Environment gcc
