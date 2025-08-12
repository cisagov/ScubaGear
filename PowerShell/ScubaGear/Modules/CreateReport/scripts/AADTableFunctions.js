/**
 * Defines the column names for each expandable table.
 * 
 * The "" column is used for the nameless column that holds the
 * "Show more" / "Show less" buttons.
 */
const TABLE_METADATA = {
    caps: {
        title: "Conditional Access Policies",
        wrapperClass: "expandable_wrapper",
        useModal: false,
        columns: [
            { name: "" },
            { name: "Name" },
            { name: "State", className: "state" },
            { name: "Users", className: "users" },
            { name: "Apps/Actions", className: "apps_actions" },
            { name: "Conditions", className: "conditions" },
            { name: "Block/Grant Access" },
            { name: "Session Controls" }
        ]
    },
    riskyApps: {
        title: "Risky Applications",
        wrapperClass: "expandable_wrapper",
        useModal: true,
        columns: [
            { name: "" },
            { name: "DisplayName" },
            { name: "IsMultiTenantEnabled", className: "multi_tenant_enabled" },
            { name: "KeyCredentials", className: "key_credentials" },
            { name: "PasswordCredentials", className: "password_credentials" },
            { name: "FederatedCredentials", className: "federated_credentials" },
            { name: "Permissions", className: "permissions" }
        ]
    },
    riskyThirdPartySPs: {
        title: "Risky Third Party Service Principals",
        wrapperClass: "expandable_wrapper",
        useModal: true,
        columns: [
            { name: "" },
            { name: "DisplayName", className: "display_name" },
            { name: "KeyCredentials", className: "key_credentials" },
            { name: "PasswordCredentials", className: "password_credentials" },
            { name: "FederatedCredentials", className: "federated_credentials" },
            { name: "Permissions", className: "permissions" }
        ]
    }
};

const normalizeColumnNames = (name) => {
    switch (name) {
        case "DisplayName": return "Display Name";
        case "IsMultiTenantEnabled": return "Multi-Tenant Enabled";
        case "KeyCredentials": return "Key Credentials";
        case "PasswordCredentials": return "Password Credentials";
        case "FederatedCredentials": return "Federated Credentials";
        case "Permissions": return "Permissions";
        default: return name;
    }
};

/**
 * Shared function to build a table with expand/collapse chevrons and truncation.
 * @param {Array} data - The data array.
 * @param {string} tableType - One of 'caps', 'riskyApps', 'riskySPs'.
 */
const buildExpandableTable = (data, tableType) => {
    if (data === undefined || data === null) {
        /*  CAP, risky app, and risky SP tables are only displayed for the AAD baseline, but
            this js file applies to all baselines. If data is null,
            then the current baseline is not AAD and we don't need to
            do anything.

            Also, note that CAP, risky app, and risky SP data are not declared in the static version of
            this file. It is prepended to the version rendered in the html
            by CreateReport.psm1.
        */
        return;
    };

    const metadata = TABLE_METADATA[tableType];
    if (!metadata) {
        console.error(`Invalid table type: ${tableType}.`);
        return;
    }

    const colNames = metadata.columns;
    const section = document.createElement("section");
    section.className = metadata.wrapperClass;
    document.querySelector("main").appendChild(section);

    section.appendChild(document.createElement("hr"));
    const h2 = document.createElement("h2");
    h2.textContent = metadata.title;
    section.appendChild(h2);

    if (data.length === 0) {
        // If there is no data, don't create a table, instead display this message
        let noDataWarning = document.createElement("p");
        noDataWarning.textContent = "No data found";
        section.appendChild(noDataWarning);
        return;
    }

    // Expand/Collapse all buttons
    const buttons = document.createElement("div");
    buttons.classList.add("buttons");
    section.appendChild(buttons);

    const expandAll = document.createElement("button");
    expandAll.appendChild(document.createTextNode("&#x2b; Expand all"));
    expandAll.title = "Expands all rows in the table below";
    expandAll.addEventListener("click", () => expandAllRows(data, tableType));
    buttons.appendChild(expandAll);

    const collapseAll = document.createElement("button");
    collapseAll.appendChild(document.createTextNode("&minus; Collapse all"));
    collapseAll.title = "Collapses all rows in the table below";
    collapseAll.addEventListener("click", () => collapseAllRows(data, tableType));
    buttons.appendChild(collapseAll);

    const table = document.createElement("table");
    table.className = `${tableType}_table`;
    section.appendChild(table);

    const thead = document.createElement("thead");
    const header = document.createElement("tr");

    colNames.forEach(col => {
        const th = document.createElement("th");
        th.textContent = col.name;

        if (col.className) th.classList.add(col.className);
        header.appendChild(th);
    });

    thead.appendChild(header);
    table.appendChild(thead);

    const tbody = document.createElement("tbody");
    table.appendChild(tbody);

    data.forEach((_, rowIndex) => {
        const tr = document.createElement("tr");

        colNames.forEach((_, colIndex) => {
            const td = document.createElement("td");

            if (colIndex === 0) {
                const img = document.createElement("img");
                img.setAttribute("src", "images/angle-right-solid.svg");
                img.setAttribute("alt", "Chevron arrow pointing right");
                img.style.width = "10px";

                const expandRowButton = document.createElement("button");
                expandRowButton.title = `Show more info for row ${rowIndex + 1}`;
                expandRowButton.classList.add("chevron");
                expandRowButton.addEventListener("click", (event) => expandRow(data, tableType, event));
                expandRowButton.rowNumber = rowIndex;
                expandRowButton.appendChild(img);
                td.appendChild(expandRowButton);
            } 
            else {
                fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
            }

            tr.appendChild(td);
        });

        tbody.appendChild(tr);
    });
}

/**
 * Fills a cell with truncated content and three-dots button (for expanding) if needed.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLElement} td The table cell to fill.
 * @param {number} rowIndex The row index (0-indexed, not counting the header row).
 * @param {number} colIndex The column index (0-indexed).
 */
const fillTruncatedCell = (data, tableType, td, rowIndex, colIndex) => {
    const colNames = TABLE_METADATA[tableType].columns;
    const col = colNames[colIndex];
    const cellData = data[rowIndex][col.name];
    const charLimit = 50;

    let content = "";
    let truncated = false;

    if (cellData === null || cellData === undefined) {
        td.textContent = "None";
        return;
    }

    // Will handle cases like (KeyCredentials, PasswordCredentials, Permissions) that have 1-many items
    // instead of the more basic case where "cellData" is a string.
    if (Array.isArray(cellData) || typeof cellData === "object") {
        const items = normalizeToArray(cellData);
        const count = items.length;

        if (TABLE_METADATA[tableType].useModal) {
            td.textContent = `${count} total`;
        }
        else {
            const first = items[0];
            td.textContent = first.toString();
        }

        truncated = true;
    }
    // Standard view of cell data which is seen in the CAPs table
    else {
        const value = cellData.toString();

        if (value.length > charLimit) {
            td.textContent = value.substring(0, charLimit);
            truncated = true;
        }
        else {
            td.textContent = value;
        }
    }

    // Don't apply truncated cell to "Name" or "DisplayName" column
    if (col.name === "Name" || col.name === "DisplayName") {
        td.textContent = cellData.toString();
        truncated = false;
    }

    if (truncated) {
        const span = document.createElement("span");
        span.appendChild(document.createTextNode("..."));

        const threeDotsButton = document.createElement("button");
        threeDotsButton.title = `Expand row ${rowIndex + 1}`;
        threeDotsButton.classList.add("truncated-dots");
        threeDotsButton.addEventListener("click", (event) => expandRow(data, tableType, event));
        threeDotsButton.rowNumber = rowIndex;
        threeDotsButton.appendChild(span);
        td.appendChild(threeDotsButton);
    }
}

/**
 * Fills a table row with expanded (full) content.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLTableRowElement} row The table row element.
 * @param {number} rowIndex The row index.
 */
const fillExpandedRow = (data, tableType, row, rowIndex) => {
    const metadata = TABLE_METADATA[tableType];
    const colNames = metadata.columns;

    for (let colIndex = 0; colIndex < colNames.length; colIndex++) {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        td.textContent = "";
        const col = colNames[colIndex];
        const cellData = data[rowIndex][col.name];

        if (colIndex === 0) {
            // We have to manually "reset" the content of the first column to an empty value,
            // then we can recreate the down-angled chevron arrow.
            const img = document.createElement("img");
            img.setAttribute("src", "images/angle-down-solid.svg");
            img.setAttribute("alt", "Chevron arrow pointing down");
            img.style.width = "14px";

            const collapseRowButton = document.createElement("button");
            collapseRowButton.title = `Show less info for row ${rowIndex + 1}`;
            collapseRowButton.classList.add("chevron");
            collapseRowButton.addEventListener("click", (event) => collapseRow(data, tableType, event));
            collapseRowButton.rowNumber = rowIndex;
            collapseRowButton.appendChild(img);
            td.appendChild(collapseRowButton);
        }
        else if (cellData && Array.isArray(cellData) && cellData.length > 1) {
            const items = normalizeToArray(cellData);

            if (items.length === 0) {
                td.textContent = "None";
                continue;
            }

            if (metadata.useModal) {
                // Assumes column name "DisplayName" or "Name" exist, may need to adjust if adding new table types
                const rowLabel = data[rowIndex].DisplayName || data[rowIndex].Name;
                const colLabel = normalizeColumnNames(col.name);

                const btn = document.createElement("button");
                btn.type = "button";
                btn.className = "view-details-button";
                btn.textContent = colLabel;
                btn.addEventListener("click", () => {
                    let node = renderKeyValueList(items);
                    const title = `${colLabel} - ${rowLabel}`;
                    openDetailsModal(title, node);
                });

                td.appendChild(btn);
            }
            else {
                td.appendChild(renderKeyValueList(items));
            }
        }
        else {
            td.textContent = cellData ?? "None";
        }
    }
}

/**
 * Fills a table row with collapsed (truncated) content and restores the chevron.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLTableRowElement} row The table row element.
 * @param {number} rowIndex The row index.
 */
const fillCollapsedRow = (data, tableType, row, rowIndex) => {
    const colNames = TABLE_METADATA[tableType].columns;

    for (let colIndex = 0; colIndex < colNames.length; colIndex++) {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
    }

    // We have to manually "reset" the content of the first column to an empty value,
    // then we can recreate the right-angled chevron arrow.
    let td = row.querySelector("td:first-child");
    td.textContent = "";
    const img = document.createElement("img");
    img.setAttribute("src", "images/angle-right-solid.svg");
    img.setAttribute("alt", "Chevron arrow pointing right");
    img.style.width = "10px";

    const expandRowButton = document.createElement("button");
    expandRowButton.title = `Show more info for row ${rowIndex + 1}`;
    expandRowButton.classList.add("chevron");
    expandRowButton.addEventListener("click", (event) => expandRow(data, tableType, event));
    expandRowButton.rowNumber = rowIndex;
    expandRowButton.appendChild(img);
    td.appendChild(expandRowButton);
}

/**
 * Fills in the row of the table indicated by the event with the full version of the row.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {Event} event The event that triggered the expansion.
 */
const expandRow = (data, tableType, event) => {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillExpandedRow(data, tableType, row, rowIndex);
}

/**
 * Expands all rows in a table.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 */
const expandAllRows = (data, tableType) => {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillExpandedRow(data, tableType, row, rowIndex);
    });
}

/**
 * Collapses a row back to truncated view.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {Event} event The event that triggered the expansion.
 */
const collapseRow = (data, tableType, event) => {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillCollapsedRow(data, tableType, row, rowIndex);
}

/**
 * Collapses all rows in a table to the truncated version.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 */
const collapseAllRows = (data, tableType) => {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillCollapsedRow(data, tableType, row, rowIndex);
    });
}

/**
 * Opens a modal component to display data in a list format.
 * 
 * @param {string} title Header for the modal.
 * @param {Node} contentNode Content to be injected into the modal.
 */
const openDetailsModal = (title, contentNode) => {
    const dialog = document.getElementById("details-dialog");
    const titleElement = document.getElementById("details-title");
    const contentElement = document.getElementById("details-content");
    const closeBtn = document.getElementById("details-close");

    if (!dialog || !titleElement || !contentElement || !closeBtn) {
        console.error("Details dialog elements not found.");
        return;
    }

    titleElement.textContent = title || "Details";
    contentElement.textContent = "";

    if (contentNode instanceof Node) contentElement.appendChild(contentNode);
    else contentElement.textContent = String(contentNode);

    const opener = document.activeElement;
    const onClose = () => {
        dialog.removeEventListener("close", onClose);
        closeBtn.removeEventListener("click", handleClose);
        if (opener && typeof opener.focus === "function") opener.focus();
    };
    const handleClose = () => dialog.close();

    dialog.addEventListener("close", onClose);
    closeBtn.addEventListener("click", handleClose);

    if (typeof dialog.showModal === "function") dialog.showModal();
    else dialog.setAttribute("open", "open");

    closeBtn.focus();
};

/**
 * Builds a unordered list of key-value pairs from an array of items.
 * 
 * @param {Array} items Array of items to be displayed.
 * @returns {HTMLElement} An unordered list element containing the key-value pairs.
 */
const renderKeyValueList = (items) => {
    const ul = document.createElement("ul");

    items.forEach(item => {
        const li = document.createElement("li");
        if (item && typeof item === "object") {
            li.innerHTML = Object.entries(item)
                .map(([k, v]) => `<strong>${k}:</strong> ${v}`)
                .join("<br>");
        }
        else {
            li.textContent = item.toString();
        }

        ul.appendChild(li);
    });

    return ul;
};