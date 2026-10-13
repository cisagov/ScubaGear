# Network Access

ScubaGear connects to Microsoft services over HTTPS (port 443) to read tenant configuration. If your agency restricts outbound traffic with a firewall, proxy, or secure web gateway, those services must be allowed.

`Get-ScubaGearEndpointRest` lists the hosts for the products you assess, so you can copy them into an allow-list request. The list is read from the ScubaGear version you have installed, so it stays current as ScubaGear changes.

## Listing the Hosts

List every host for every product in a commercial tenant:

```powershell
Get-ScubaGearEndpointRest
```

Choose the products and environment, and print one host per line:

```powershell
Get-ScubaGearEndpointRest -ProductNames exo, teams -M365Environment gcchigh -Format Hosts
```

Produce a table for a ticket or document and save it to a file:

```powershell
Get-ScubaGearEndpointRest -M365Environment gcc -Domain contoso -Format Markdown -OutFile .\scubagear-hosts.md
```

Copy the host list to the clipboard:

```powershell
Get-ScubaGearEndpointRest -M365Environment dod -Domain contoso -Format Hosts -Clipboard
```

### Parameters

| Parameter | Description |
| --- | --- |
| `-ProductNames` | The products to include. Accepts the same values as `Invoke-SCuBA`. Defaults to all products. |
| `-M365Environment` | `commercial` (default), `gcc`, `gcchigh`, or `dod`. |
| `-Domain` | Your tenant name, for example `contoso` for `contoso.onmicrosoft.com`. Fills in the SharePoint admin host name. |
| `-Format` | `Object` (default), `Hosts`, `Csv`, `Json`, or `Markdown`. |
| `-OutFile` | Writes the output to a file. With `-Format Object`, the file contains the `Hosts` format. |
| `-Clipboard` | Copies the output to the clipboard. With `-Format Object`, the clipboard receives the `Hosts` format. |

With the default `Object` format, each result has the host, port, base URL, products, environment, and purpose.

## What the List Includes

* Microsoft Graph, which every product uses.
* The admin API for each selected product: Exchange Online, Security and Compliance, SharePoint, Teams, Power Platform, and Power BI.

The list does not include:

* Microsoft sign-in (Entra ID) hosts.
* Hosts that are used only to install or update ScubaGear and its dependencies.

> [!NOTE]
> SharePoint admin hosts contain your tenant name. Without `-Domain`, the host appears as `<tenant>-admin.sharepoint.com`. Replace `<tenant>` with your tenant name or pass `-Domain`.

Run the command again after you update ScubaGear. Hosts can be added or changed between releases.
