/**
 * Adds the red, green, yellow, and gray coloring to the individual report pages.
 */
const colorRows = () => {
    let rows = document.querySelectorAll('tr');
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
            console.error(`Error in colorRows, i = ${i}`);
            console.error(error);
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
        let capDiv = document.createElement("div");
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
        expandAll.title = "Expand all";
        expandAll.addEventListener("click", expandAllCAPs);
        buttons.appendChild(expandAll);

        let collapseAll = document.createElement("button");
        collapseAll.appendChild(document.createTextNode("&minus; Collapse all"));
        collapseAll.title = "Collapse all";
        collapseAll.addEventListener("click", collapseAllCAPs);
        buttons.appendChild(collapseAll);

        let table = document.createElement("table");
        table.setAttribute("class", "caps_table");
        capDiv.appendChild(table);

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
        table.appendChild(header);

        for (let i = 0; i < caps.length; i++) {
            let tr = document.createElement("tr");
            for (let j = 0; j < capColNames.length; j++) {
                let td = document.createElement("td");
                fillTruncatedCell(td, i,j);
                tr.appendChild(td);
            }

            let img = document.createElement("img");
            img.setAttribute('src', 'images/angle-right-solid.svg');
            img.setAttribute('alt', 'Show more');
            img.setAttribute('title', 'Show more');
            img.style.width = '10px';
            img.rowNumber = i;
            img.addEventListener("click", expandCAPRow);
            tr.querySelectorAll('td')[0].appendChild(img);
            table.appendChild(tr);
        }
    }
    catch (error) {
        console.error("Error in fillCAPTable");
        console.error(error);
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

        if (truncated) {
            let span = document.createElement("span");
            span.appendChild(document.createTextNode("..."));
            span.title = "Show more";
            span.rowNumber = i;
            span.addEventListener("click", expandCAPRow);
            td.appendChild(span);
        }
    }
    catch (error) {
        console.error(`Error in fillTruncatedCell, i = ${i}, j = ${j}`);
        console.error(error);
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
        img.style.width = '10px';
        img.setAttribute('alt', 'Show more');
        img.setAttribute('title', 'Show more');
        img.rowNumber = i;
        img.addEventListener("click", expandCAPRow);
        tr.querySelectorAll('td')[0].appendChild(img);
    }
    catch (error) {
        console.error("Error in hideCAPRow");
        console.error(error);
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
            buttons[i].click();
        }
    }
    catch (error) {
        console.error("Error in expandAllCAPs");
        console.error(error);
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
            buttons[i].click();
        }
    }
    catch (error) {
        console.error("Error in collapseAllCAPs");
        console.error(error);
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
                img.setAttribute('alt', 'Show less');
                img.setAttribute('title', 'Show less');
                img.style.width = '14px';
                img.rowNumber = i;
                img.addEventListener("click", hideCAPRow);
                tr.querySelectorAll('td')[0].appendChild(img);
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
        console.error("Error in expandCAPRow");
        console.error(error);
    }
}

window.addEventListener('DOMContentLoaded', (event) => {
    colorRows();
    fillCAPTable();
    mountDarkMode("Individual Report");
});