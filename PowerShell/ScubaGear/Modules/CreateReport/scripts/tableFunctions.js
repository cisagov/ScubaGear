/**
 * Adds the red, green, yellow, and gray coloring to the individual report pages.
 */
const colorRows = () => {
    //Adjusted the querySelector to only use the rows which have policy data within them instead of every table in report
    let rows = document.querySelectorAll('.policy-data tr');
    const requirementCol = 1;
    const statusCol = 2;
    const criticalityCol = 3;
    for (let i = 0; i < rows.length; i++) {
        try {
            if (rows[i].children[requirementCol].innerHTML.startsWith("[DELETED]")) {
                rows[i].style.color = "var(--test-deleted-color)";
                rows[i].style.background = "var(--test-other)";
            }
            else if (rows[i].children[statusCol].innerHTML.startsWith("Bug")){
                rows[i].style.background = "var(--test-bug-color)";
            }
            else if (rows[i].children[statusCol].innerHTML === "Fail") {
                rows[i].style.background = "var(--test-fail)";
            }
            else if (rows[i].children[statusCol].innerHTML === "Warning") {
                rows[i].style.background = "var(--test-warning)";
            }
            else if (rows[i].children[statusCol].innerHTML === "Pass") {
                rows[i].style.background = "var(--test-pass)";
            }
            else if (rows[i].children[statusCol].innerHTML === "Omitted") {
                rows[i].style.background = "var(--test-other)";
            }
            else if (rows[i].children[statusCol].innerHTML === "Incorrect result") {
                if (rows[i].children[criticalityCol].innerHTML === "Shall") {
                    rows[i].style.background = "linear-gradient(to right, var(--test-fail), var(--test-pass))";
                }
                else if (rows[i].children[criticalityCol].innerHTML === "Should") {
                    rows[i].style.background = "linear-gradient(to right, var(--test-warning), var(--test-pass))";
                }
                else {
                    // This should never happen
                    console.log(`Unexpected criticality for incorrect result, ${rows[i].children[criticalityCol].innerHTML}.`);
                }
            }
            else if (rows[i].children[criticalityCol].innerHTML.includes("Not-Implemented")) {
                rows[i].style.background = "var(--test-other)";
            }
            else if (rows[i].children[criticalityCol].innerHTML.includes("3rd Party")) {
                rows[i].style.background = "var(--test-other)";
            }
            else if (rows[i].children[statusCol].innerHTML.includes("Error")) {
                rows[i].style.background = "var(--test-fail)";
                rows[i].querySelectorAll('td')[statusCol].style.borderColor = "var(--border-color)";
                rows[i].querySelectorAll('td')[statusCol].style.color = "var(--test-error-color)";
            }
        }
        catch (error) {
            console.error(`Error in colorRows, i = ${i}`, error);
        }
    }
}

/**
 * Reusable truncation/expand helper for any table cell.
 * @param {HTMLElement} td - The table cell to populate.
 * @param {*} value - The value to display (string, array, or object).
 * @param {Object} [options] - Options for truncation.
 * @param {number} [options.charLimit] - Max characters for string truncation.
 * @param {number} [options.itemLimit] - Max items for array truncation.
 */
function makeTruncatableCell(td, value, options = {}) {
    const charLimit = options.charLimit ?? 50;
    const itemLimit = options.itemLimit ?? 3;

    const renderValue = (val, truncate = false) => {
        if (val === null || val === undefined) return document.createTextNode("");
        if (Array.isArray(val)) {
            const ul = document.createElement("ul");
            (truncate ? val.slice(0, itemLimit) : val).forEach(item => {
                const li = document.createElement("li");
                if (typeof item === "object" && item !== null) {
                    li.textContent = Object.entries(item).map(([k, v]) => `${k}: ${v}`).join(", ");
                } else {
                    li.textContent = item;
                }
                ul.appendChild(li);
            });
            return ul;
        }
        if (typeof val === "object") {
            return document.createTextNode(
                Object.entries(val).map(([k, v]) => `${k}: ${v}`).join(", ")
            );
        }
        if (typeof val === "string" && truncate && val.length > charLimit) {
            return document.createTextNode(val.substring(0, charLimit));
        }
        return document.createTextNode(val);
    };

    let needsTruncate = false;
    if (Array.isArray(value) && value.length > itemLimit) needsTruncate = true;
    if (typeof value === "string" && value.length > charLimit) needsTruncate = true;

    td.innerHTML = "";
    td.appendChild(renderValue(value, needsTruncate));

    if (needsTruncate) {
        const button = document.createElement("button");
        button.className = "truncated-dots";
        button.type = "button";
        button.title = "Show more";
        button.textContent = "...";
        button.addEventListener("click", () => {
            const expanded = button.getAttribute("data-expanded") === "true";
            td.innerHTML = "";
            td.appendChild(renderValue(value, !expanded && needsTruncate));
            button.setAttribute("data-expanded", (!expanded).toString());
            button.title = expanded ? "Show more" : "Show less";
            button.textContent = expanded ? "..." : " show less";
            td.appendChild(button);
        });
        button.setAttribute("data-expanded", "false");
        td.appendChild(button);
    }
}

/**
 * Truncates the specified DNS table to the specified number of rows.
 * @param {number} logIndex The index of the table in the list of DNS tables.
 * @param {number} maxRows The number of rows to truncate the table to.
 */
const truncateDNSTable = (logIndex, maxRows) => {
    try {
        const ROW_INCREMENT = 10;
        let dnsLog = document.querySelectorAll('.dns-logs')[logIndex];
        let rows = dnsLog.querySelector('table').querySelectorAll('tr');
        for (let i = 0; i < rows.length; i++) {
            if (i > maxRows) {
                rows[i].style.display = 'none';
            }
            else {
                rows[i].style.display = 'table-row';
            }
        }
        dnsLog.querySelectorAll('.show-more').forEach(e => e.remove());
        if (rows.length > maxRows) {
            let showMoreMessage = document.createElement('p');
            showMoreMessage.classList.add('show-more');
            showMoreMessage.innerHTML = `${rows.length-maxRows} rows hidden. `;
            showMore = document.createElement('button');
            showMore.innerHTML = "Show more.";
            showMore.setAttribute('type', 'button');
            showMore.classList.add('show-more');
            showMore.onclick = () => {truncateDNSTable(logIndex, maxRows+ROW_INCREMENT);};
            showMoreMessage.appendChild(showMore);
            dnsLog.appendChild(showMoreMessage);
        }
    }
    catch (error) {
        console.error(`Error in truncateDNSTable`, error);
    }
}

/**
 * Truncates any DNS table that has more than maxRows rows.
 * @param {number} maxRows The number of rows to truncate the tables to.
 */
const truncateDNSTables = (maxRows) => {
    try {
        let dnsLogs = document.querySelectorAll('.dns-logs');
        for (let i = 0; i < dnsLogs.length; i++) {
            truncateDNSTable(i, maxRows);
        }
    }
    catch (error) {
        console.error(`Error in truncateDNSTables`, error);
    }
}


/**
 * Truncates list of domains without SPF to maxDomains.
* @param {number} maxDomains The number of domains to truncate the list to.
 */
const truncateSPFList = (maxDomains) => {
    try {
        const ROW_INCREMENT = 10;
        let spfList = document.querySelector('#spf-domains');
        if (spfList === null) {
            // No SPF list present so this report isn't for EXO
            return;
        }
        let domains = spfList.querySelectorAll('li');
        for (let i = 0; i < domains.length; i++) {
            if (i > maxDomains) {
                domains[i].style.display = 'none';
            }
            else {
                domains[i].style.display = 'list-item';
            }
        }
        spfList.querySelectorAll('.show-more').forEach(e => e.remove());
        if (domains.length > maxDomains) {
            let showMoreMessage = document.createElement('p');
            showMoreMessage.classList.add('show-more');
            showMoreMessage.innerHTML = `${domains.length-maxDomains} domains hidden. `;
            showMore = document.createElement('button');
            showMore.innerHTML = "Show more.";
            showMore.setAttribute('type', 'button');
            showMore.classList.add('show-more');
            showMore.onclick = () => {truncateSPFList(maxDomains+ROW_INCREMENT);};
            showMoreMessage.appendChild(showMore);
            spfList.appendChild(showMoreMessage);
        }
    }
    catch (error) {
        console.error(`Error in truncateSPFList`, error);
    }
}

/**
 * Creates the risky applications table at the end of the AAD report.
 * For all other reports (e.g., teams), this function does nothing.
 * @param {Array} riskyApps Array of risky application objects.
 */
const buildRiskyAppsTable = (riskyApps) => {
    if (!Array.isArray(riskyApps) || riskyApps.length === 0) return;

    const columns = [
        "DisplayName",
        "IsMultiTenantEnabled",
        "KeyCredentials",
        "PasswordCredentials",
        "FederatedCredentials",
        "Permissions"
    ];

    const section = document.createElement("section");
    section.id = "risky_apps_wrapper";
    document.querySelector("main").appendChild(section);

    const h2 = document.createElement("h2");
    h2.textContent = "Risky Applications";
    section.appendChild(h2);

    const table = document.createElement("table");
    table.className = "risky_table";
    section.appendChild(table);

    const thead = document.createElement("thead");
    const headerRow = document.createElement("tr");
    columns.forEach(col => {
        const th = document.createElement("th");
        th.textContent = col;
        headerRow.appendChild(th);
    });
    thead.appendChild(headerRow);
    table.appendChild(thead);

    const tbody = document.createElement("tbody");
    riskyApps.forEach(app => {
        const row = document.createElement("tr");
        columns.forEach(col => {
            const td = document.createElement("td");
            td.appendChild(formatRiskyCell(app[col]));
            row.appendChild(td);
        });
        tbody.appendChild(row);
    });
    table.appendChild(tbody);
};

/**
 * Creates the risky third-party SP table at the end of the AAD report.
 * For all other reports (e.g., teams), this function does nothing.
 * @param {Array} riskySPs Array of risky third party service principal objects.
 */
const buildRiskyThirdPartySPsTable = (riskySPs) => {
    if (!Array.isArray(riskySPs) || riskySPs.length === 0) return;

    const columns = [
        "DisplayName",
        "KeyCredentials",
        "PasswordCredentials",
        "FederatedCredentials",
        "Permissions"
    ];

    const section = document.createElement("section");
    section.id = "risky_third_party_sps_wrapper";
    document.querySelector("main").appendChild(section);

    const h2 = document.createElement("h2");
    h2.textContent = "Risky Third Party Service Principals";
    section.appendChild(h2);

    const table = document.createElement("table");
    table.className = "risky_table";
    section.appendChild(table);

    const thead = document.createElement("thead");
    const headerRow = document.createElement("tr");
    columns.forEach(col => {
        const th = document.createElement("th");
        th.textContent = col;
        headerRow.appendChild(th);
    });
    thead.appendChild(headerRow);
    table.appendChild(thead);

    const tbody = document.createElement("tbody");
    riskySPs.forEach(sp => {
        const row = document.createElement("tr");
        columns.forEach(col => {
            const td = document.createElement("td");
            td.appendChild(formatRiskyCell(sp[col]));
            row.appendChild(td);
        });
        tbody.appendChild(row);
    });
    table.appendChild(tbody);
};

/**
 * Formats a cell value for display in the risky tables.
 * Handles arrays, objects, and primitives.
 * @param {*} val The value to format.
 * @returns {Node} A DOM node for the cell.
 */
const formatRiskyCell = (val) => {
    if (val === null || val === undefined) {
        return document.createTextNode("");
    }
    if (Array.isArray(val)) {
        const ul = document.createElement("ul");
        val.forEach(item => {
            const li = document.createElement("li");
            if (typeof item === "object" && item !== null) {
                li.textContent = Object.entries(item).map(([k, v]) => `${k}: ${v}`).join(", ");
            } else {
                li.textContent = item;
            }
            ul.appendChild(li);
        });
        return ul;
    }
    if (typeof val === "object") {
        return document.createTextNode(
            Object.entries(val).map(([k, v]) => `${k}: ${v}`).join(", ")
        );
    }
    return document.createTextNode(val);
};

/**
 * Defines the column names for each expandable table.
 * 
 * The "" column is used for the nameless column that holds the
 * "Show more" / "Show less" buttons.
 */
const TABLE_COL_NAMES = {
    caps: [
        { name: "" },
        { name: "Name" },
        { name: "State", className: "state" },
        { name: "Users", className: "users" },
        { name: "Apps/Actions", className: "apps_actions" },
        { name: "Conditions", className: "conditions" },
        { name: "Block/Grant Access" },
        { name: "Session Controls" }
    ],
    riskyApps: [
        { name: "" },
        { name: "DisplayName" },
        { name: "IsMultiTenantEnabled" },
        { name: "KeyCredentials" },
        { name: "PasswordCredentials" },
        { name: "FederatedCredentials" },
        { name: "Permissions" }
    ],
    riskyThirdPartySPs: [
        { name: "" },
        { name: "DisplayName" },
        { name: "KeyCredentials" },
        { name: "PasswordCredentials" },
        { name: "FederatedCredentials" },
        { name: "Permissions" }
    ]
};

/**
 * Shared function to build a table with expand/collapse chevrons and truncation.
 * @param {Array} data - The data array.
 * @param {string} tableType - One of 'caps', 'riskyApps', 'riskySPs'.
 * @param {string} sectionId - The section id for the table.
 * @param {string} title - The table title.
 */
function buildExpandableTable(data, tableType, sectionId, title) {
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

    if (!TABLE_COL_NAMES.hasOwnProperty(tableType)) {
        console.error(`Invalid table type: ${tableType}.`);
        return;
    }

    const colNames = TABLE_COL_NAMES[tableType];
    const section = document.createElement("section");
    section.id = sectionId;
    document.querySelector("main").appendChild(section);

    section.appendChild(document.createElement("hr"));
    const h2 = document.createElement("h2");
    h2.textContent = title;
    section.appendChild(h2);

    if (data.length === 0) {
        // If there is no data, don't create a table, instead display this message
        let noDataWarning = document.createElement("p");
        noDataWarning.innerHTML = "No data found"
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

    data.forEach((_, i) => {
        const tr = document.createElement("tr");

        colNames.forEach((_, j) => {
            const td = document.createElement("td");
            if (j === 0) {
                const img = document.createElement("img");
                img.setAttribute('src', 'images/angle-right-solid.svg');
                img.setAttribute('alt', `Chevron arrow pointing right`);
                img.style.width = '10px';

                const expandRowButton = document.createElement("button");
                expandRowButton.title = `Show more info for row ${i + 1}`;
                expandRowButton.classList.add("chevron");
                expandRowButton.addEventListener("click", (event) => expandRow(data, tableType, event));
                expandRowButton.rowNumber = i;
                expandRowButton.appendChild(img);
                td.appendChild(expandRowButton);
            } 
            else {
                fillTruncatedCell(data, tableType, td, i, j);
            }
            tr.appendChild(td);
        });
        tbody.appendChild(tr);
    });
}

/**
 * Fills a cell with truncated content and a three-dots button if needed.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLElement} td The table cell to fill.
 * @param {number} i The row index (0-indexed, not counting the header row).
 * @param {number} j The column index (0-indexed).
 */
function fillTruncatedCell(data, tableType, td, i, j) {
    const colNames = TABLE_COL_NAMES[tableType];
    const charLimit = 50;
    let content = "";
    let truncated = false;
    const col = colNames[j];

    if (data[i][col.name] === null) {
        content = "None";
    }
    else if (data[i][col.name] && Array.isArray(data[i][col.name]) && data[i][col.name].length > 1) {
        content = data[i][col.name][0];
        truncated = true;
    }
    else {
        content = data[i][col.name];
    }

    if (typeof content === "string" && content.length > charLimit) {
        td.innerHTML = content.substring(0, charLimit);
        truncated = true;
    }
    else {
        td.innerHTML = content;
    }

    // Don't apply truncated cell to "Name" or "DisplayName" column
    if (col.name === "Name" || col.name === "DisplayName") {
        td.innerHTML = content;
        truncated = false;
    }

    if (truncated) {
        const span = document.createElement("span");
        span.appendChild(document.createTextNode("..."));

        const threeDotsButton = document.createElement("button");
        threeDotsButton.title = `Expand row ${i + 1}`;
        threeDotsButton.classList.add("truncated-dots");
        threeDotsButton.addEventListener("click", (event) => expandRow(data, tableType, event));
        threeDotsButton.rowNumber = i;
        threeDotsButton.appendChild(span);
        td.appendChild(threeDotsButton);
    }
}

/**
 * Fills in the row of the table indicated by the event with the full version of the row.
 * For AAD only.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {Event} event The event that triggered the expansion.
 */
function expandRow(data, tableType, event) {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillExpandedRow(data, tableType, row, rowIndex);
}

/**
 * Collapses a row back to truncated view.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {Event} event The event that triggered the expansion.
 */
function hideRow(data, tableType, event) {
    let row = event.currentTarget.closest("tr");
    let rowIndex = event.currentTarget.rowNumber;
    fillCollapsedRow(data, tableType, row, rowIndex);
}

/**
 * Expands all rows in a table.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 */
function expandAllRows(data, tableType) {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillExpandedRow(data, tableType, row, rowIndex);
    });
}

/**
 * Collapses all rows in a table to the truncated version.
 * 
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 */
function collapseAllRows(data, tableType) {
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((row, rowIndex) => {
        fillCollapsedRow(data, tableType, row, rowIndex);
    });
}

/**
 * Fills a table row with expanded (full) content.
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLTableRowElement} row The table row element.
 * @param {number} rowIndex The row index.
 */
function fillExpandedRow(data, tableType, row, rowIndex) {
    const colNames = TABLE_COL_NAMES[tableType];

    for (let colIndex = 0; colIndex < colNames.length; colIndex++) {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        td.innerHTML = "";
        const col = colNames[colIndex];

        if (colIndex === 0) {
            const img = document.createElement("img");
            img.setAttribute('src', 'images/angle-down-solid.svg');
            img.setAttribute('alt', `Chevron arrow pointing down`);
            img.style.width = '14px';

            const collapseRowButton = document.createElement("button");
            collapseRowButton.title = `Show less info for row ${rowIndex + 1}`;
            collapseRowButton.classList.add("chevron");
            collapseRowButton.addEventListener("click", (event) => hideRow(data, tableType, event));
            collapseRowButton.rowNumber = rowIndex;
            collapseRowButton.appendChild(img);
            td.appendChild(collapseRowButton);
        }
        else if (data[rowIndex][col.name] && Array.isArray(data[rowIndex][col.name])) {
            const ul = document.createElement("ul");
            data[rowIndex][col.name].forEach(item => {
                const li = document.createElement("li");
                li.textContent = typeof item === "object" ? JSON.stringify(item) : item;
                ul.appendChild(li);
            });
            td.appendChild(ul);
        } else {
            td.innerHTML = data[rowIndex][col.name] ?? "";
        }
    }
}

/**
 * Fills a table row with collapsed (truncated) content and restores the chevron.
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLTableRowElement} row The table row element.
 * @param {number} rowIndex The row index.
 */
function fillCollapsedRow(data, tableType, row, rowIndex) {
    const colNames = TABLE_COL_NAMES[tableType];

    for (let colIndex = 0; colIndex < colNames.length; colIndex++) {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        fillTruncatedCell(data, tableType, td, rowIndex, colIndex);
    }

    let td = row.querySelector("td:first-child");
    td.innerHTML = "";
    const img = document.createElement("img");
    img.setAttribute('src', 'images/angle-right-solid.svg');
    img.setAttribute('alt', `Chevron arrow pointing right`);
    img.style.width = '10px';

    const expandRowButton = document.createElement("button");
    expandRowButton.title = `Show more info for row ${rowIndex + 1}`;
    expandRowButton.classList.add("chevron");
    expandRowButton.addEventListener("click", (event) => expandRow(data, tableType, event));
    expandRowButton.rowNumber = rowIndex;
    expandRowButton.appendChild(img);
    td.appendChild(expandRowButton);
}

