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
const buildExpandableTable = (data, tableType, sectionId, title) => {
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
const fillTruncatedCell = (data, tableType, td, i, j) => {
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
 * Fills a table row with expanded (full) content.
 * @param {Array} data The table content.
 * @param {string} tableType The type of table (e.g., 'caps', 'riskyApps', 'riskySPs').
 * @param {HTMLTableRowElement} row The table row element.
 * @param {number} rowIndex The row index.
 */
const fillExpandedRow = (data, tableType, row, rowIndex) => {
    const colNames = TABLE_COL_NAMES[tableType];

    for (let colIndex = 0; colIndex < colNames.length; colIndex++) {
        let td = row.querySelector(`td:nth-of-type(${colIndex + 1})`);
        td.innerHTML = "";
        const col = colNames[colIndex];
        const cellData = data[rowIndex][col.name];

        if (colIndex === 0) {
            const img = document.createElement("img");
            img.setAttribute('src', 'images/angle-down-solid.svg');
            img.setAttribute('alt', `Chevron arrow pointing down`);
            img.style.width = '14px';

            const collapseRowButton = document.createElement("button");
            collapseRowButton.title = `Show less info for row ${rowIndex + 1}`;
            collapseRowButton.classList.add("chevron");
            collapseRowButton.addEventListener("click", (event) => collapseRow(data, tableType, event));
            collapseRowButton.rowNumber = rowIndex;
            collapseRowButton.appendChild(img);
            td.appendChild(collapseRowButton);
        }
        else if (cellData && Array.isArray(cellData) && cellData.length > 1) {
            const items = (val) => Array.isArray(val) ? val : (val ? [val] : []);
            console.log(items);
            if (items.length === 0) {
                td.innerHTML = "None";
                continue;
            }

            const label = col.name;

            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'view-details-button';
            btn.textContent = label;
            btn.addEventListener('click', () => {
                let node = renderKeyValueList(items);
                const title = `${normalizeRiskyColumnNames(col.name)} — ${data[rowIndex]?.DisplayName ?? data[rowIndex]?.Name ?? 'Row ' + (rowIndex + 1)}`;
                openDetailsModal(title, node);
            });

            td.appendChild(btn);
        }
        else {
            td.innerHTML = cellData ?? "None";
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
const fillCollapsedRow = (data, tableType, row, rowIndex) => {
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

/**
 * Fills in the row of the table indicated by the event with the full version of the row.
 * For AAD only.
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

const openDetailsModal = (title, contentNode) => {
    const dialog = document.getElementById('details-dialog');
    const titleEl = document.getElementById('details-title');
    const contentEl = document.getElementById('details-content');
    const closeBtn = document.getElementById('details-close');

    if (!dialog || !titleEl || !contentEl || !closeBtn) {
        console.error('Details dialog elements not found.');
        return;
    }

    // Basic a11y: ensure heading has text
    titleEl.textContent = title || 'Details';

    // Reset content
    contentEl.innerHTML = '';
    if (contentNode instanceof Node) contentEl.appendChild(contentNode);
    else contentEl.textContent = String(contentNode ?? '');

    // Focus management
    const opener = document.activeElement;
    const onClose = () => {
        dialog.removeEventListener('close', onClose);
        closeBtn.removeEventListener('click', handleCloseClick);
        if (opener && typeof opener.focus === 'function') opener.focus();
    };
    const handleCloseClick = () => dialog.close();

    dialog.addEventListener('close', onClose);
    closeBtn.addEventListener('click', handleCloseClick);

    if (typeof dialog.showModal === 'function') dialog.showModal();
    else dialog.setAttribute('open', 'open');
    closeBtn.focus();
};

const createViewDetailsButton = (label, onClick) => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'view-details-button';
    btn.textContent = label;
    btn.addEventListener('click', onClick);
    return btn;
};

const renderKeyValueList = (items) => {
    const container = document.createElement('div');
    const ul = document.createElement('ul');
    ul.style.listStyle = 'none';
    ul.style.padding = '0';

    items.forEach(obj => {
        const li = document.createElement('li');
        li.style.padding = '8px 0';
        li.style.borderBottom = '1px solid #eee';
        if (obj && typeof obj === 'object') {
            li.innerHTML = Object.entries(obj)
                .map(([k, v]) => `<strong>${k}:</strong> ${v}`)
                .join('<br>');
        } 
        else {
            li.textContent = String(obj);
        }
        ul.appendChild(li);
    });
    container.appendChild(ul);
    return container;
};

const normalizeRiskyColumnNames = (name) => {
    switch (name) {
        case 'Permissions': return 'Permissions';
        case 'KeyCredentials': return 'Key credentials';
        case 'PasswordCredentials': return 'Password credentials';
        case 'FederatedCredentials': return 'Federated credentials';
        default: return name;
    }
};

const normalizeToArray = (val) => Array.isArray(val) ? val : (val ? [val] : []);