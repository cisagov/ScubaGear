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
 * For the conditional access policy table. For AAD only.
 * The "" column is used for the nameless column that holds the
 * "Show more" / "Show less" buttons.
 */
const capColNames = ["", "Name", "State", "Users", "Apps/Actions", "Conditions", "Block/Grant Access", "Session Controls"];

/**
 * Creates the conditional access policy table at the end of the AAD report.
 * For all other reports (e.g., teams), this function does nothing.
 */
const fillCAPTable = () => {
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
                fillTruncatedCell(td, i,j);
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
            expandRowButton.addEventListener("click", expandCAPRow);
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
 * @param {HTMLElement} td The specific td that will be populated.
 * @param {number} i The row number (0-indexed, not counting the header row).
 * @param {number} j The the column number (0-indexed).
 */
const fillTruncatedCell = (td, i, j) => {
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
            threeDotsButton.addEventListener("click", expandCAPRow);
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
 * @param {HTMLElement} event The target of the event.
 */
const hideCAPRow = (event) => {
    try {
        let i = event.currentTarget.rowNumber;
        let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
        because nth-of-type is indexed from 1 and to account for the header row */
        for (let j = 0; j < capColNames.length; j++) {
            let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
            fillTruncatedCell(td, i, j);
        }
        let img = document.createElement("img");
        img.setAttribute('src', 'images/angle-right-solid.svg');
        img.setAttribute('alt', `Chevron arrow pointing right`);
        img.style.width = '10px';

        let expandRowButton = document.createElement("button");
        expandRowButton.title = `Show more info for the ${tr.children[1].innerText} policy`;
        expandRowButton.classList.add("chevron");
        expandRowButton.addEventListener("click", expandCAPRow);
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
 * @param {HTMLElement} event The target of the event.
 */
const expandCAPRow = (event) => {
    try {
        let i = event.currentTarget.rowNumber;
        let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
        because nth-of-type is indexed from 1 and to account for the header row */
        for (let j = 0; j < capColNames.length; j++) {
            let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
            fillTruncatedCell(td, i, j);
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
                collapseRowButton.addEventListener("click", hideCAPRow);
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


window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;
    colorRows();
    fillCAPTable();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode("Individual Report");
});