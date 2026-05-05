/**
 * This object configures all expandable tables in the AAD report.
 * 
 * The keys are the main identifiers used throughout the AAD table functions. They also determines the CSS class 
 * applied to a given table element, e.g. `${tableType}_table`.
 * 
 * title:
 *   - H2 heading displayed above the table.
 * wrapperClass:
 *   - CSS class applied to the <section> wrapping the table.
 * useModal:
 *   - If true, clicking on a cell with multiple items will open a modal with the full list.
 *     If false, it will expand the row in place.
 * columns:
 *   - An array of objects, each representing a column in the table.
 *     The first entry is "" as a placeholder for the expand/collapse arrows. Otherwise each entry
 *     contains the name of the column along with an optional class name if custom styling is required.
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
        title: "Applications with Risky Permissions",
        wrapperClass: "expandable_wrapper",
        useModal: true,
        columns: [
            { name: "" },
            { name: "DisplayName", className: "display_name" },
            { name: "SeverityScore", className: "severity_score" },
            { name: "IsMultiTenantEnabled", className: "multi_tenant_enabled" },
            { name: "KeyCredentials", className: "key_credentials" },
            { name: "PasswordCredentials", className: "password_credentials" },
            { name: "FederatedCredentials", className: "federated_credentials" },
            { name: "Permissions", className: "permissions" }
        ]
    },
    riskyThirdPartySPs: {
        title: "Third Party Service Principals with Risky Permissions",
        wrapperClass: "expandable_wrapper",
        useModal: true,
        columns: [
            { name: "" },
            { name: "DisplayName", className: "display_name" },
            { name: "SeverityScore", className: "severity_score" },
            { name: "PrivilegedRoles", className: "privileged_roles" },
            { name: "KeyCredentials", className: "key_credentials" },
            { name: "PasswordCredentials", className: "password_credentials" },
            { name: "FederatedCredentials", className: "federated_credentials" },
            { name: "Permissions", className: "permissions" }
        ]
    }
};

/* Associate the table type with the sorting column and direction (asc/desc)
 *
 * { [tableType]: { column: "SeverityScore", ascending: "asc"/"desc" } }
 */
const tableSortState = {};

/**
 * Sorts a data array by a given column and direction.
 * SeverityScore uses SEVERITY_SORT_ORDER for ordering rather than alphabetical.
 *
 * @param {Array} data - The data array to sort.
 * @param {string} column - The column name to sort by.
 * @param {string} direction - "asc" or "desc".
 * @returns {Array} - Sorted copy of the data array.
 */
const sortData = (data, column, direction) => {
    return [...data].sort((a, b) => {
        let valueA = a[column];
        let valueB = b[column];

        // Numbers
        if (typeof valueA === "number" && typeof valueB === "number") {
            valueA = valueA ?? 0;
            valueB = valueB ?? 0;
        }
        // Arrays/objects (e.g. Permissions, Credentials) sort by count
        else if ((Array.isArray(valueA) || (typeof valueA === "object" && valueA !== null)) &&
                 (Array.isArray(valueB) || (typeof valueB === "object" && valueB !== null))) {
            valueA = normalizeToArray(valueA).length;
            valueB = normalizeToArray(valueB).length;
        }
        // Booleans
        else if (typeof valueA === "boolean" && typeof valueB === "boolean") {
            valueA = valueA ? 0 : 1;
            valueB = valueB ? 0 : 1;
        }
        // Strings
        else {
            valueA = String(valueA ?? "").toLowerCase();
            valueB = String(valueB ?? "").toLowerCase();
        }

        if (valueA < valueB) return direction === "asc" ? -1 : 1;
        if (valueA > valueB) return direction === "asc" ? 1 : -1;
        return 0;
    })
};

/**
 * Creates a sort indicator <img> icon for the given state.
 * 
 * @param {"asc" | "desc" | "none"} state - The sort state.
 * @returns {HTMLImageElement} - An <img> element.
 */
const createSortIcon = (state) => {
    const img = document.createElement("img");
    const map = {
        asc:  { src: "images/arrow-up.svg", alt: "Sorted ascending" },
        desc: { src: "images/arrow-down.svg", alt: "Sorted descending" },
        none: { src: "images/arrow-down-up.svg", alt: "Sort" }
    };

    const metadata = map[state] || map.none;
    img.setAttribute("src", metadata.src);
    img.setAttribute("alt", metadata.alt);
    img.classList.add("sort-icon");
    return img;
};

/**
 * Updates the sort indicator icons on all column headers for the given table.
 *
 * @param {string} tableType - The type of table (e.g., "riskyApps", "riskyThirdPartySPs").
 * @param {string} activeColumn - The currently sorted column name.
 * @param {string} direction - "asc" or "desc".
 */
const updateSortIndicators = (tableType, activeColumn, direction) => {
    document.querySelectorAll(`.${tableType}_table thead th`).forEach(th => {
        const indicator = th.querySelector(".sort-indicator");
        if (!indicator) return;

        const col = th.dataset.column;
        indicator.textContent = "";
        if (col === activeColumn) {
            indicator.appendChild(createSortIcon(direction));
            indicator.setAttribute("aria-label", direction === "asc" ? "sorted ascending" : "sorted descending");
            indicator.classList.add("sort-indicator--active");
            th.setAttribute("aria-sort", direction === "asc" ? "ascending" : "descending");
        }
        else {
            indicator.appendChild(createSortIcon("none"));
            indicator.removeAttribute("aria-label");
            indicator.classList.remove("sort-indicator--active");
            th.setAttribute("aria-sort", "none");
        }
    });
};

/**
 * Handles a column header click to sort the table by that column.
 * Toggles between ascending and descending; defaults to descending on first click.
 *
 * @param {Array} data - The original data array.
 * @param {string} tableType - The type of table.
 * @param {string} column - The column name to sort by.
 */
const handleSortClick = (data, tableType, column) => {
    const currentState = tableSortState[tableType] || {};
    const direction = (currentState.column === column && currentState.direction === "desc")
        ? "asc"
        : "desc";

    tableSortState[tableType] = { column, direction };

    const sorted = sortData(data, column, direction);

    // Replace data in-place so all existing references (expand/collapse) stay in sync
    data.splice(0, data.length, ...sorted);

    const tbody = document.querySelector(`.${tableType}_table tbody`);
    const colNames = TABLE_METADATA[tableType].columns;

    tbody.querySelectorAll("tr").forEach((row, rowIndex) => {
        colNames.forEach((_, colIndex) => {
            const td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
            td.textContent = "";

            if (colIndex === 0) {
                td.appendChild(
                    createRowActionButton({
                        title: `Show more info for row ${rowIndex + 1}`,
                        className: "chevron",
                        rowIndex,
                        onClick: (event) => expandRow(data, tableType, event),
                        contentBuilder: () => createChevronIcon("right", 10)
                    })
                );
            }
            else {
                fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
            }
        });
    });

    updateSortIndicators(tableType, column, direction);
};

/**
 * Formatting function to make column names pretty.
 * 
 * @param {string} name - The original column name.
 * @returns {string} - The normalized column name.
 */
const normalizeColumnNames = (name) => {
    switch (name) {
        case "DisplayName": return "Display Name";
        case "SeverityScore": return "Risk Score";
        case "PrivilegedRoles": return "Privileged Roles";
        case "IsMultiTenantEnabled": return "Multi-Tenant Enabled";
        case "KeyCredentials": return "Key Credentials";
        case "PasswordCredentials": return "Password Credentials";
        case "FederatedCredentials": return "Federated Credentials";
        default: return name;
    }
};

/**
 * Creates a chevron <img> icon for right/down arrows.
 * 
 * @param {string} direction - Direction of the chevron arrow.
 * @param {number} width - Icon width in pixels.
 * @returns {HTMLImageElement} - An <img> element.
 */
const createChevronIcon = (direction, width) => {
    const img = document.createElement("img");
    const map = {
        right: { src: "images/angle-right-solid.svg", alt: "Chevron arrow pointing right" },
        down:  { src: "images/angle-down-solid.svg",  alt: "Chevron arrow pointing down" }
    };

    const metadata = map[direction] || map.right;
    img.setAttribute("src", metadata.src);
    img.setAttribute("alt", metadata.alt);
    img.style.width = `${width}px`;
    return img;
};

/**
 * Creates a generic row-action button with custom content (img/span/etc.).
 * contentBuilder must return a Node that will be appended inside the button.
 * 
 * @param {string} title - Title for the button.
 * @param {string} className - Optional CSS class for the button.
 * @param {number} rowIndex - The row index (0-indexed, not counting the header row).
 * @param {function} onClick - Click event handler for the button.
 * @param {function} contentBuilder - Function that returns inner Node content.
 */
const createRowActionButton = ({ title, className, rowIndex, onClick, contentBuilder }) => {
    const btn = document.createElement("button");
    btn.title = title;
    btn.rowNumber = rowIndex;
    btn.addEventListener("click", onClick);
    if (className) btn.classList.add(className);

    const content = contentBuilder();
    if (content) btn.appendChild(content);
    return btn;
};

/**
 * Colors a row in the risk apps/SPs table based on its severity level.
 * 
 * Critical = red
 * High = orange
 * Medium = yellow
 * Low/None = no color
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "riskyApps", "riskySPs").
 */
/*const colorRiskyRows = (data, tableType) => {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        const severityLevel = data[rowIndex]?.SeverityLevel;
        switch (severityLevel) {
            case "Critical":
                row.style.background = "var(--severity-critical)";
                break;
            case "High":
                row.style.background = "var(--severity-high)";
                break;
            case "Medium":
                row.style.background = "var(--severity-medium)";
                break;
            case "Low":
                row.style.background = "var(--severity-low)";
                break;
            default: 
                row.style.background = "transparent";
                break;
        }
    });
};*/

/**
 * Shared function to build a table with expand/collapse chevrons and truncation.
 * 
 * @param {Array} data - The data array.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 */
const buildExpandableTable = (data, tableType) => {
    try {
        if (data === undefined || data === null) {
            /*  CAP, risky app, and risky SP tables are only displayed for the AAD baseline, but this js file 
                applies to all baselines. If data is null, then the current baseline is not AAD 
                and we don't need to do anything.

                Also, note that CAP, risky app, and risky SP data are not declared in the static version of
                this file. It is prepended to the version rendered in the html by CreateReport.psm1.
                Inspect one of the individual HTML reports and open the <head> tag, there will be <script>
                tags with type="application/json" with the raw data.
            */
            return;
        };

        const metadata = TABLE_METADATA[tableType];
        if (!metadata) {
            console.error(`Invalid table type: ${tableType}.`);
            return;
        }

        const isSortable = tableType === "riskyApps" || tableType === "riskyThirdPartySPs";
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
        expandAll.classList.add("btn-primary");
        expandAll.appendChild(document.createTextNode("&#x2b; Expand all"));
        expandAll.title = "Expands all rows in the table below";
        expandAll.addEventListener("click", () => expandAllRows(data, tableType));
        buttons.appendChild(expandAll);

        const collapseAll = document.createElement("button");
        collapseAll.classList.add("btn-primary");
        collapseAll.appendChild(document.createTextNode("&minus; Collapse all"));
        collapseAll.title = "Collapses all rows in the table below";
        collapseAll.addEventListener("click", () => collapseAllRows(data, tableType));
        buttons.appendChild(collapseAll);

        // Sort risky tables by SeverityScore in descending order by default
        if (isSortable) {
            const sorted = sortData(data, "SeverityScore", "desc");
            data.splice(0, data.length, ...sorted);
            tableSortState[tableType] = { column: "SeverityScore", direction: "desc" };
        }

        const table = document.createElement("table");
        table.className = `${tableType}_table`;
        section.appendChild(table);

        const thead = document.createElement("thead");
        const header = document.createElement("tr");

        colNames.forEach(col => {
            const th = document.createElement("th");
            if (col.className) th.classList.add(col.className);
            
            // Exclude 0th column since it's set to "" for the expand/collapse arrows.
            if (isSortable && col.name !== "") {
                th.dataset.column = col.name;
                th.setAttribute("aria-sort", col.name === "SeverityScore" ? "descending" : "none");

                const btn = document.createElement("button");
                btn.classList.add("sort-btn");
                btn.title = `Sort by ${normalizeColumnNames(col.name)}`;
                btn.addEventListener("click", () => handleSortClick(data, tableType, col.name));

                const label = document.createElement("span");
                label.textContent = normalizeColumnNames(col.name);

                const indicator = document.createElement("span");
                indicator.classList.add("sort-indicator");
                indicator.setAttribute("aria-hidden", "true");
                
                if (col.name === "SeverityScore") {
                    // Default sorted column - show desc icon immediately
                    indicator.appendChild(createSortIcon("desc"));
                    indicator.classList.add("sort-indicator--active");
                }
                else {
                    // All other columns - show neutral icon only on hover
                    indicator.appendChild(createSortIcon("none"));
                }

                btn.appendChild(label);
                btn.appendChild(indicator);
                th.appendChild(btn);
            }
            else {
                th.textContent = normalizeColumnNames(col.name);
            }

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
                    td.appendChild(
                        createRowActionButton({
                            title: `Show more info for row ${rowIndex + 1}`,
                            className: "chevron",
                            rowIndex,
                            onClick: (event) => expandRow(data, tableType, event),
                            contentBuilder: () => createChevronIcon("right", 10)
                        })
                    );
                } 
                else {
                    fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
                }

                tr.appendChild(td);
            });

            tbody.appendChild(tr);
        });

        //if (tableType === "riskyApps" || tableType === "riskyThirdPartySPs") {
        //    colorRiskyRows(data, tableType);
        //}
    }
    catch (error) {
        console.error(`Error building expandable table for ${tableType}:`, error);
    }
}

/**
 * Creates a severity badge element for the given severity level.
 * 
 * @param {string} level - "Critical", "High", "Medium", or "Low".
 * @returns {HTMLElement} - A styled <span> badge element.
 */
/*const createSeverityBadge = (level) => {
    const span = document.createElement("span");
    span.classList.add("severity-badge", level);
    span.textContent = level ?? "Unknown";
    return span;
};*/

/**
 * Fills a cell with truncated content and three-dots button (for expanding) if needed.
 *
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 * @param {HTMLElement} td - The table cell to fill.
 * @param {number} rowIndex - The row index (0-indexed, not counting the header row).
 * @param {number} colIndex - The column index (0-indexed).
 */
const fillTruncatedCell = (data, tableType, td, rowIndex, colIndex) => {
    const colNames = TABLE_METADATA[tableType].columns;
    const col = colNames[colIndex];
    const cellData = data[rowIndex][col.name];
    const charLimit = 50;
    let truncated = false;

    if (cellData === null || cellData === undefined) {
        td.textContent = "None";
        return;
    }

    if (col.name === "SeverityScore") {
        td.textContent = cellData;
        return;
    }

    // Will handle cases like (KeyCredentials, PasswordCredentials, Permissions) that have 1-many items
    // instead of the more basic case where "cellData" is a string.
    if (Array.isArray(cellData) || typeof cellData === "object") {
        const items = normalizeToArray(cellData);
        const count = items.length;

        if (TABLE_METADATA[tableType].useModal) {
            td.textContent = `Total: ${count}`;
        }
        else {
            const first = items[0];
            td.textContent = String(first);
        }

        truncated = true;
    }
    // Standard view of cell data which is seen in the CAPs table
    else {
        const value = String(cellData);

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
        td.textContent = String(cellData);
        truncated = false;
    }

    if (truncated) {
        td.appendChild(
            createRowActionButton({
                title: `Expand row ${rowIndex + 1}`,
                className: "truncated-dots",
                rowIndex,
                onClick: (event) => expandRow(data, tableType, event),
                contentBuilder: () => {
                    const span = document.createElement("span");
                    span.appendChild(document.createTextNode("..."));
                    return span;
                }
            })
        );
    }
}

/**
 * Fills a table row with expanded (full) content.
 *
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 * @param {HTMLTableRowElement} row - The table row element.
 * @param {number} rowIndex - The row index.
 */
const fillExpandedRow = (data, tableType, row, rowIndex) => {
    const metadata = TABLE_METADATA[tableType];
    const colNames = metadata.columns;

    colNames.forEach((col, colIndex) => {
        const cellData = data[rowIndex][col.name];

        // We have to manually "reset" the content of the first column to an empty value,
        // then we can recreate the down-angled chevron arrow.
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        td.textContent = "";

        if (colIndex === 0) {
            td.appendChild(
                createRowActionButton({
                    title: `Show less info for row ${rowIndex + 1}`,
                    className: "chevron",
                    rowIndex,
                    onClick: (event) => collapseRow(data, tableType, event),
                    contentBuilder: () => createChevronIcon("down", 14)
                })
            );
            return;
        }

        // SeverityScore - display numeric value directly
        if (col.name === "SeverityScore") {
            td.textContent = cellData ?? "None";
            return;
        }
        
        if (cellData && (Array.isArray(cellData) || typeof cellData === "object")) {
            const items = normalizeToArray(cellData);
            const count = items.length;

            if (count === 0) {
                td.textContent = "None";
                return;
            }


            // Set the "useModal" flag inside of TABLE_METADATA to true if you want to use a modal for displaying details.
            // Otherwise, cell data will be displayed inline.
            if (metadata.useModal) {
                // Assumes column name "DisplayName" or "Name" exist, will need to adjust if adding new table types
                const rowLabel = data[rowIndex].DisplayName || data[rowIndex].Name;
                const colLabel = normalizeColumnNames(col.name);

                const ul = renderSummaryList(col.name, items);
                if (ul) td.appendChild(ul);

                const btn = document.createElement("button");
                btn.type = "button";
                btn.classList.add("btn-primary", "view-details-button");
                btn.textContent = `View ${count} ${colLabel}`;
                btn.addEventListener("click", () => {
                    let dataType = "";
                    if (col.name === "Permissions") dataType = "Permissions";
                    if (col.name === "KeyCredentials" || col.name === "PasswordCredentials") dataType = "Credentials";
                    if (col.name === "PrivilegedRoles") dataType = "PrivilegedRoles";

                    let node = renderKeyValueList(items, { advanced: true, dataType });
                    const title = `${rowLabel} - ${colLabel}`;
                    openDetailsModal(title, node);
                });

                td.appendChild(btn);
            }
            else {
                td.appendChild(renderKeyValueList(items));
            }

            return;
        }

        td.textContent = cellData ?? "None";
    });
}

/**
 * Fills a table row with collapsed (truncated) content and restores the chevron.
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 * @param {HTMLTableRowElement} row - The table row element.
 * @param {number} rowIndex - The row index.
 */
const fillCollapsedRow = (data, tableType, row, rowIndex) => {
    const colNames = TABLE_METADATA[tableType].columns;

    colNames.forEach((_, colIndex) => {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
    });

    // We have to manually "reset" the content of the first column to an empty value,
    // then we can recreate the right-angled chevron arrow.
    let td = row.querySelector("td:first-child");
    td.textContent = "";
    td.appendChild(
        createRowActionButton({
            title: `Show more info for row ${rowIndex + 1}`,
            className: "chevron",
            rowIndex,
            onClick: (event) => expandRow(data, tableType, event),
            contentBuilder: () => createChevronIcon("right", 10)
        })
    );
}

/**
 * Fills in a single row of the table indicated by the event with the full version of the row.
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 * @param {Event} event - The event that triggered the expansion.
 */
const expandRow = (data, tableType, event) => {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillExpandedRow(data, tableType, row, rowIndex);
}

/**
 * Expands all rows in a table.
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 */
const expandAllRows = (data, tableType) => {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillExpandedRow(data, tableType, row, rowIndex);
    });

    //if (tableType === "riskyApps" || tableType === "riskyThirdPartySPs") {
    //    colorRiskyRows(data, tableType);
    //}
}

/**
 * Collapses a single row back to truncated view.
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 * @param {Event} event - The event that triggered the expansion.
 */
const collapseRow = (data, tableType, event) => {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillCollapsedRow(data, tableType, row, rowIndex);
}

/**
 * Collapses all rows in a table to the truncated version.
 * 
 * @param {Array} data - The table content.
 * @param {string} tableType - The type of table (e.g., "caps", "riskyApps", "riskySPs").
 */
const collapseAllRows = (data, tableType) => {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillCollapsedRow(data, tableType, row, rowIndex);
    });

    //if (tableType === "riskyApps" || tableType === "riskyThirdPartySPs") {
    //    colorRiskyRows(data, tableType);
    //}
}

/**
 * Opens a modal component to display data in a list format.
 * 
 * @param {string} title - Header for the modal.
 * @param {Node} contentNode - Content to be injected into the modal.
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
 * @param {Array} items - Array of items to be displayed.
 * @param {Object} options - Optional settings.
 *  - advanced: If true, applies advanced formatting.
 *  - dataType: If specified, applies special formatting based on the data type (e.g., "credentials", "permissions").
 * @returns {HTMLElement} - An unordered list element containing the key-value pairs.
 */
const renderKeyValueList = (items, options = {}) => {
    if (!options.advanced) {
        const ul = document.createElement("ul");

        // Iterate through the list of "Key Credentials", "Permissions", etc.
        items.forEach(item => {
            const li = document.createElement("li");

            if (item && typeof item === "object") {
                const entries = Object.entries(item);

                // Iterate through the key/value pairs for each object, e.g. key = "IsRisky", value = true
                entries.forEach(([key, value], idx) => {
                    const strong = document.createElement("strong");
                    strong.textContent = `${key}:`;
                    li.appendChild(strong);

                    let content = value;

                    // Start/End dates come in the format of /Date(1675800895000)/ which isn't a standard Date() format.
                    // Parse it then apply .toLocaleString() to get the M/D/YYYY HH:MM:SS format.
                    if (typeof value === "string" && (key === "StartDateTime" || key === "EndDateTime")) {
                        const date = parseDotNetDate(value);
                        content = date ? date.toLocaleString() : value;
                    }

                    li.appendChild(document.createTextNode(` ${String(content)}`));

                    if (idx < entries.length - 1) {
                        li.appendChild(document.createElement("br"));
                    }
                });
            }
            else {
                li.textContent = String(item);
            }

            ul.appendChild(li);
        });

        return ul;
    }

    // renderAdvancedKeyValueList and associated search/filter methods can be found in KeyValueListFunctions.js
    return renderAdvancedKeyValueList(items, options.dataType);
};

/**
 * Builds an unordered list summarizing data such as:
 *   - active/expired credentials
 *   - admin consented permissions
 *   - non-admin consented permissions
 *   - risky permissions
 * 
 * @param {string} colName - The column name from TABLE_METADATA.columns (e.g., "KeyCredentials", "Permissions").
 * @param {Array} items - The normalized array of items to summarize.
 * @returns {HTMLElement|null} - An unordered list element containing the summary.
 */
const renderSummaryList = (colName, items) => {
    const count = items.length;

    const makeUl = () => {
        const ul = document.createElement("ul");
        ul.className = "summary-list";
        return ul;
    };

    const addItem = (ul, label, value) => {
        const li = document.createElement("li");
        const strong = document.createElement("strong");
        strong.textContent = `${label}:`;
        li.appendChild(strong);
        li.appendChild(document.createTextNode(` ${String(value)}`));
        ul.appendChild(li);
    };

    // Only display active/expired counts for key/password credentials
    if (colName === "KeyCredentials" || colName === "PasswordCredentials") {
        const now = new Date();
        let active = 0, expired = 0;

        items.forEach(credential => {
            if (!credential || typeof credential !== "object") return;

            const start = parseDotNetDate(credential.StartDateTime);
            const end = parseDotNetDate(credential.EndDateTime);

            if (start && end) {
                if (start <= now && end >= now) {
                    active++;
                    return;
                }
                
                if (end < now) {
                    expired++;
                    return;
                }
            }
        });

        const ul = makeUl();
        addItem(ul, "Total", count);
        addItem(ul, "Active", active);
        addItem(ul, "Expired", expired);
        return ul;
    }

    // Federated credentials do not expire so only display the total count
    if (colName === "FederatedCredentials") {
        const ul = makeUl();
        addItem(ul, "Total", count);
        return ul;
    }

    if (colName === "PrivilegedRoles") {
        const ul = makeUl();
        addItem(ul, "Total", count);
        return ul;
    }

    if (colName === "Permissions") {
        let applicationPermissions = 0, delegatedPermissions = 0, adminConsented = 0, notAdminConsented = 0, risky = 0;

        items.forEach(permission => {
            if (!permission || typeof permission !== "object") return;

            // Handle application/delegated permissions
            if (permission.RoleType === "Application") applicationPermissions++;
            if (permission.RoleType === "Delegated") delegatedPermissions++;

            // Handle admin consented permissions
            if (permission.IsAdminConsented === true) adminConsented++;
            else notAdminConsented++;

            // Handle risky permissions
            if (permission.IsRisky === true) risky++;
        });

        const ul = makeUl();
        addItem(ul, "Total", count);
        addItem(ul, "Application Permissions", applicationPermissions);
        addItem(ul, "Delegated Permissions", delegatedPermissions);
        addItem(ul, "Admin Consented", adminConsented);
        addItem(ul, "Not Admin Consented", notAdminConsented);
        addItem(ul, "Risky", risky);
        return ul;
    }

    return null;
}