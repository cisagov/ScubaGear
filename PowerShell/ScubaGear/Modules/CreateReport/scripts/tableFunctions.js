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
 * For the conditional access policy table. For AAD only.
 * The "" column is used for the nameless column that holds the
 * "Show more" / "Show less" buttons.
 */
const capColNames = ["", "Name", "State", "Users", "Apps/Actions", "Conditions", "Block/Grant Access", "Session Controls"];

/**
 * Creates the conditional access policy table at the end of the AAD report.
 * For all other reports (e.g., teams), this function does nothing.
 * @param {Array} caps An array of conditional access policies.
 */
const fillCAPTable = (caps) => {
    if (caps === undefined || caps === null) {
        /*  The CAP table is only displayed for the AAD baseline, but
            this js file applies to all baselines. If caps is null,
            then the current baseline is not AAD and we don't need to
            do anything.

            Also, note that caps isn't declared in the static version of
            this file. It is prepended to the version rendered in the html
            by CreateReport.ps1.
        */
       return;
    }
    try {
        let capDiv = document.createElement("section");
        capDiv.setAttribute("id", "caps");
        document.querySelector("main").appendChild(capDiv);

        capDiv.appendChild(document.createElement("hr"));
        h2 = document.createElement("h2");
        h2.innerHTML = "Conditional Access Policies";
        capDiv.appendChild(h2);

        if (caps.length === 0) {
            // If there are no CAPs, don't create a table, instead display this message
            let noCapWarning = document.createElement("p");
            noCapWarning.innerHTML = "No conditional access policies found"
            capDiv.appendChild(noCapWarning);
            return;
        }

        let buttons = document.createElement("div");
        buttons.classList.add("buttons");
        capDiv.appendChild(buttons);

        let expandAll = document.createElement("button");
        expandAll.appendChild(document.createTextNode("&#x2b; Expand all"));
        expandAll.title = "Expands all rows in the conditional access policy table below";
        expandAll.addEventListener("click", expandAllCAPs);
        buttons.appendChild(expandAll);

        let collapseAll = document.createElement("button");
        collapseAll.appendChild(document.createTextNode("&minus; Collapse all"));
        collapseAll.title = "Collapses all rows in the conditional access policy table below";
        collapseAll.addEventListener("click", collapseAllCAPs);
        buttons.appendChild(collapseAll);

        let table = document.createElement("table");
        table.setAttribute("class", "caps_table");
        capDiv.appendChild(table);

        let tbody = document.createElement("tbody");
        table.appendChild(tbody);

        let header = document.createElement("tr");
        for (let i = 0; i < capColNames.length; i++) {
            let th = document.createElement("th");
            if (capColNames[i] === "Apps/Actions") {
                th.setAttribute("class", "apps_actions");
            }
            else if (capColNames[i] === "State") {
                th.setAttribute("class", "state");
            }
            else if (capColNames[i] === "Users") {
                th.setAttribute("class", "users");
            }
            else if (capColNames[i] === "Conditions") {
                th.setAttribute("class", "conditions");
            }
            th.innerHTML = capColNames[i];
            header.appendChild(th);
        }
        tbody.appendChild(header);

        for (let i = 0; i < caps.length; i++) {
            let tr = document.createElement("tr");
            for (let j = 0; j < capColNames.length; j++) {
                let td = document.createElement("td");
                fillTruncatedCell(caps, td, i,j);
                tr.appendChild(td);
            }

            // Create chevron icon in the DOM 
            let img = document.createElement("img");
            img.setAttribute('src', 'images/angle-right-solid.svg');
            img.setAttribute('alt', `Chevron arrow pointing right`);
            img.style.width = '10px';

            //Append the above image as a child 
            let expandRowButton = document.createElement("button");
            expandRowButton.title = `Show more info for the ${tr.children[1].innerText} policy`;
            expandRowButton.classList.add("chevron");
            expandRowButton.addEventListener("click", (event) => expandCAPRow(caps, event));
            expandRowButton.rowNumber = i;
            expandRowButton.appendChild(img);
            tr.querySelectorAll('td')[0].appendChild(expandRowButton);
            tbody.appendChild(tr);
        }
    }
    catch (error) {
        console.error(`Error in fillCAPTable`, error);
    }
}

/**
 * Fills in the truncated version of the given cell of the AAD conditional
 * access policy table. For AAD only.
 * @param {Array} caps An array of conditional access policies.
 * @param {HTMLElement} td The specific td that will be populated.
 * @param {number} i The row number (0-indexed, not counting the header row).
 * @param {number} j The the column number (0-indexed).
 */
const fillTruncatedCell = (caps, td, i, j) => {
    try {
        const charLimit = 50;
        let content = "";
        let truncated = false;
        if (capColNames[j] === "") {
            content = ""
        }
        else if (caps[i][capColNames[j]].constructor === Array && caps[i][capColNames[j]].length > 1) {
            content = caps[i][capColNames[j]][0];
            truncated = true;
        }
        else {
            content = caps[i][capColNames[j]];
        }

        if (content.length > charLimit) {
            td.innerHTML = content.substring(0, charLimit);
            truncated = true;
        }
        else {
            td.innerHTML = content;
        }

        // Don't apply truncated cell to "Name" column 
        if (j === 1) {
            td.innerHTML = content;
            truncated = false;
        }

    
        if (truncated) {
            let span = document.createElement("span");
            span.appendChild(document.createTextNode("..."));

            let threeDotsButton = document.createElement("button");
            threeDotsButton.title = `Three dots that expands row ${i + 1} of the CAP table`;
            threeDotsButton.classList.add("truncated-dots");
            threeDotsButton.addEventListener("click", (event) => expandCAPRow(caps, event));
            threeDotsButton.rowNumber = i;
            threeDotsButton.appendChild(span);
            td.appendChild(threeDotsButton);
        }
    }
    catch (error) {
        console.error(`Error in fillTruncatedCell, i = ${i}, j = ${j}`, error);
    }
}

/**
 * Fills in the row of the conditional access policy table indicated by the
 * event with the truncated version of the row. For AAD only.
 * @param {Array} caps An array of conditional access policies.
 * @param {HTMLElement} event The target of the event.
 */
const hideCAPRow = (caps, event) => {
    try {
        let i = event.currentTarget.rowNumber;
        let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
        because nth-of-type is indexed from 1 and to account for the header row */
        for (let j = 0; j < capColNames.length; j++) {
            let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
            fillTruncatedCell(caps, td, i, j);
        }
        let img = document.createElement("img");
        img.setAttribute('src', 'images/angle-right-solid.svg');
        img.setAttribute('alt', `Chevron arrow pointing right`);
        img.style.width = '10px';

        let expandRowButton = document.createElement("button");
        expandRowButton.title = `Show more info for the ${tr.children[1].innerText} policy`;
        expandRowButton.classList.add("chevron");
        expandRowButton.addEventListener("click", (event) => expandCAPRow(caps, event));
        expandRowButton.rowNumber = i;
        expandRowButton.appendChild(img);
        tr.querySelectorAll('td')[0].appendChild(expandRowButton);
    }
    catch (error) {
        console.error(`Error in hideCAPRow`, error);
    }
}

/**
 * Expands all rows of the conditional access policy table to the full version.
 * For AAD only.
 */
const expandAllCAPs = () => {
    try {
        let buttons = document.querySelectorAll("img[src*='angle-right-solid.svg']");
        for (let i = 0; i < buttons.length; i++) {
            buttons[i].parentNode.click();
        }
    }
    catch (error) {
        console.error(`Error in expandAllCAPs`, error);
    }
}

/**
 * Shrinks all rows of the conditional access policy table to the truncated
 * version. For AAD only.
 */
const collapseAllCAPs = () => {
    try {
        let buttons = document.querySelectorAll("img[src*='angle-down-solid.svg']");
        for (let i = 0; i < buttons.length; i++) {
            buttons[i].parentNode.click();
        }
    }
    catch (error) {
        console.error(`Error in collapseAllCAPs`, error);
    }
}

/**
 * Fills in the row of the conditional access policy table indicated by the
 * event with the full version of the row. For AAD only.
 * @param {Array} caps An array of conditional access policies.
 * @param {HTMLElement} event The target of the event.
 */
const expandCAPRow = (caps, event) => {
    try {
        let i = event.currentTarget.rowNumber;
        let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
        because nth-of-type is indexed from 1 and to account for the header row */
        for (let j = 0; j < capColNames.length; j++) {
            let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
            fillTruncatedCell(caps, td, i, j);
            td.innerHTML = "";
            if (capColNames[j] === "") {
                td.innerHTML = "";
                let img = document.createElement("img");
                img.setAttribute('src', 'images/angle-down-solid.svg');
                img.setAttribute('alt', `Chevron arrow pointing down`);
                img.style.width = '14px';

                // For accessibility append the above image as a child 
                let collapseRowButton = document.createElement("button");
                collapseRowButton.title = `Show less info for the ${tr.children[1].innerText} policy`;
                collapseRowButton.classList.add("chevron");
                collapseRowButton.addEventListener("click", (event) => hideCAPRow(caps, event));
                collapseRowButton.rowNumber = i;
                collapseRowButton.appendChild(img);
                tr.querySelectorAll('td')[0].appendChild(collapseRowButton);
            }
            else if (caps[i][capColNames[j]].constructor === Array && caps[i][capColNames[j]].length > 1) {
                let ul = document.createElement("ul");
                for (let k = 0; k < caps[i][capColNames[j]].length; k++) {
                    let li = document.createElement("li");
                    li.innerHTML = caps[i][capColNames[j]][k];
                    ul.appendChild(li);
                }
                td.appendChild(ul);
            }
            else {
                td.innerHTML = caps[i][capColNames[j]];
            }
        }
    }
    catch (error) {
        console.error(`Error in expandCAPRow`, error);
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
    riskySPs: [
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
    collapseAll.appendChild(document.createTextNode("&#x2b; Collapse all"));
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
                fillTruncatedCellGeneric(data, tableType, td, i, j);
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
function fillTruncatedCellGeneric(data, tableType, td, i, j) {
    const colNames = TABLE_COL_NAMES[tableType];
    const charLimit = 50;
    let content = "";
    let truncated = false;
    const col = colNames[j];

    if (data[i][col.name] && Array.isArray(data[i][col.name]) && data[i][col.name].length > 1) {
        content = data[i][col.name][0];
        truncated = true;
    }
    else {
        content = data[i][col.name];
    }

    if (content.length > charLimit) {
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
    const colNames = TABLE_COL_NAMES[tableType];
    let i = event.currentTarget.rowNumber;
    let tr = event.currentTarget.closest("tr");

    for (let j = 0; j < colNames.length; j++) {
        let td = tr.querySelector(`td:nth-of-type(${j + 1})`);
        td.innerHTML = "";

        if (j === 0) {
            const img = document.createElement("img");
            img.setAttribute('src', 'images/angle-down-solid.svg');
            img.setAttribute('alt', `Chevron arrow pointing down`);
            img.style.width = '14px';

            const collapseRowButton = document.createElement("button");
            collapseRowButton.title = `Show less info for row ${i + 1}`;
            collapseRowButton.classList.add("chevron");
            collapseRowButton.addEventListener("click", (event) => hideRow(data, tableType, event));
            collapseRowButton.rowNumber = i;
            collapseRowButton.appendChild(img);
            td.appendChild(collapseRowButton);
        }
        else if (data[i][colNames[j].name] && Array.isArray(data[i][colNames[j].name])) {
            const ul = document.createElement("ul");

            data[i][colNames[j].name].forEach(item => {
                const li = document.createElement("li");
                li.innerHTML = typeof item === "object" ? JSON.stringify(item) : item;
                ul.appendChild(li);
            });
            td.appendChild(ul);
        } else {
            td.innerHTML = data[i][colNames[j].name] ?? "";
        }
    }
}

/**
 * Collapses a row back to truncated view.
 */
function hideRow(data, tableType, event) {
    const colNames = TABLE_COL_NAMES[tableType];
    let i = event.currentTarget.rowNumber;
    let tr = event.currentTarget.closest("tr");
    for (let j = 0; j < colNames.length; j++) {
        let td = tr.querySelector(`td:nth-of-type(${j + 1})`);
        fillTruncatedCellGeneric(data, tableType, td, i, j);
    }
    // Restore right chevron
    let td = tr.querySelector("td:first-child");
    td.innerHTML = "";
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

/**
 * Expands all rows in a table.
 */
function expandAllRows(data, tableType) {
    const colNames = TABLE_COL_NAMES[tableType];
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((tr, i) => {
        for (let j = 0; j < colNames.length; j++) {
            let td = tr.querySelector(`td:nth-of-type(${j + 1})`);
            if (j === 0) {
                // Down chevron
                td.innerHTML = "";
                const img = document.createElement("img");
                img.setAttribute('src', 'images/angle-down-solid.svg');
                img.setAttribute('alt', `Chevron arrow pointing down`);
                img.style.width = '14px';

                const collapseRowButton = document.createElement("button");
                collapseRowButton.title = `Show less info for row ${i + 1}`;
                collapseRowButton.classList.add("chevron");
                collapseRowButton.addEventListener("click", (event) => hideRow(data, tableType, event));
                collapseRowButton.rowNumber = i;
                collapseRowButton.appendChild(img);
                td.appendChild(collapseRowButton);
            } else if (data[i][colNames[j]] && Array.isArray(data[i][colNames[j]])) {
                const ul = document.createElement("ul");
                data[i][colNames[j]].forEach(item => {
                    const li = document.createElement("li");
                    li.textContent = typeof item === "object" ? JSON.stringify(item) : item;
                    ul.appendChild(li);
                });
                td.appendChild(ul);
            } else {
                td.innerHTML = data[i][colNames[j]] ?? "";
            }
        }
    });
}

/**
 * Collapses all rows in a table.
 */
function collapseAllRows(data, tableType) {
    const colNames = TABLE_COL_NAMES[tableType];
    document.querySelectorAll(`.${tableType}_table tbody tr`).forEach((tr, i) => {
        for (let j = 0; j < colNames.length; j++) {
            let td = tr.querySelector(`td:nth-of-type(${j + 1})`);
            fillTruncatedCellGeneric(data, tableType, td, i, j);
        }
        // Restore right chevron
        let td = tr.querySelector("td:first-child");
        td.innerHTML = "";
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
    });
}