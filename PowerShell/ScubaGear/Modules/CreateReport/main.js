function colorRows() {
    let rows = document.querySelectorAll('tr');
    for (let i = 0; i < rows.length; i++) {
        if (rows[i].children[1].innerHTML == "Fail") {
            rows[i].style.background = "#deb8b8";
        }
        else if (rows[i].children[1].innerHTML == "Warning") {
            rows[i].style.background = "#fff7d6";
        }
        else if (rows[i].children[1].innerHTML == "Pass") {
            rows[i].style.background = "#d5ebd5";
        }
        else if (rows[i].children[2].innerHTML.includes("Not-Implemented")) {
            rows[i].style.background = "#ebebf2";
        }
        else if (rows[i].children[2].innerHTML.includes("3rd Party")) {
            rows[i].style.background = "#ebebf2";
        }
        else if (rows[i].children[1].innerHTML.includes("Error")) {
            rows[i].style.background = "#deb8b8";
            rows[i].querySelectorAll('td')[1].style.borderColor = "black";
            rows[i].querySelectorAll('td')[1].style.color = "#d10000";
        }
    }
}

/* For AAD Conditional Access Policies */
let capColNames = ["Name", "", "State", "Users", "Apps/Actions", "Conditions", "Block/Grant Access", "Session Controls"];

function fillCAPTable() {
    /* For AAD Conditional Access Policies */
    if (caps == null) {
        /*  The CAP table is only displayed for the AAD baseline, but
            this js file applies to all baselines. If caps is null,
            then the current baseline is not AAD and we don't need to
            do anything.
        */
       return;
    }
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

    let expandAll = document.createElement("span");
    expandAll.classList.add("button");
    expandAll.appendChild(document.createTextNode("&#x2b; Expand all"));
    expandAll.title = "Expand all";
    expandAll.addEventListener("click", expandAllCAPs);
    buttons.appendChild(expandAll);

    let collapseAll = document.createElement("span");
    collapseAll.classList.add("button");
    collapseAll.appendChild(document.createTextNode("&minus; Collapse all"));
    collapseAll.title = "Collapse all";
    collapseAll.addEventListener("click", collapseAllCAPs);
    buttons.appendChild(collapseAll);

    let table = document.createElement("table");
    capDiv.appendChild(table);
    let header = document.createElement("tr");
    for (let i = 0; i < capColNames.length; i++) {
        let th = document.createElement("th");
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
        img.setAttribute('src', 'angle-right-solid.svg');
        img.setAttribute('alt', 'Show more');
        img.setAttribute('title', 'Show more');
        img.style.width = '10px';
        img.rowNumber = i;
        img.addEventListener("click", expandCAPRow);
        tr.querySelectorAll('td')[1].appendChild(img);
        table.appendChild(tr);
    }
}

function fillTruncatedCell(td, i, j) {
    /*  For AAD Conditional Access Policies
        i is the row number (0-indexed, not counting the header row)
        j is the column number (0-indexed)
    */
    let charLimit = 50;
    let content = "";
    let truncated = false;
    if (capColNames[j] == "") {
        content = ""
    }
    else if (caps[i][capColNames[j]].constructor === Array) {
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

function hideCAPRow(evt) {
    /* For AAD Conditional Access Policies */
    let i = evt.currentTarget.rowNumber;
    let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
    because nth-of-type is indexed from 1 and to account for the header row */
    for (let j = 0; j < capColNames.length; j++) {
        let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
        fillTruncatedCell(td, i, j);
    }
    let img = document.createElement("img");
    img.setAttribute('src', 'angle-right-solid.svg');
    img.style.width = '10px';
    img.setAttribute('alt', 'Show more');
    img.setAttribute('title', 'Show more');
    img.rowNumber = i;
    img.addEventListener("click", expandCAPRow);
    tr.querySelectorAll('td')[1].appendChild(img);
}

function expandAllCAPs() {
    /* For AAD Conditional Access Policies */
    let buttons = document.querySelectorAll("img[src*='angle-right-solid.svg']");
    for (let i = 0; i < buttons.length; i++) {
        buttons[i].click();
    }
}

function collapseAllCAPs() {
    /* For AAD Conditional Access Policies */
    let buttons = document.querySelectorAll("img[src*='angle-down-solid.svg']");
    for (let i = 0; i < buttons.length; i++) {
        buttons[i].click();
    }
}

function expandCAPRow(evt) {
    /* For AAD Conditional Access Policies */
    let i = evt.currentTarget.rowNumber;
    let tr = document.querySelector("#caps tr:nth-of-type(" + (i+2).toString() + ")"); /*i+2
    because nth-of-type is indexed from 1 and to account for the header row */
    for (let j = 0; j < capColNames.length; j++) {
        let td = tr.querySelector("td:nth-of-type(" + (j+1).toString() + ")");
        fillTruncatedCell(td, i, j);
        td.innerHTML = "";
        if (capColNames[j] == "") {
            td.innerHTML = "";
            let img = document.createElement("img");
            img.setAttribute('src', 'angle-down-solid.svg');
            img.setAttribute('alt', 'Show less');
            img.setAttribute('title', 'Show less');
            img.style.width = '14px';
            img.rowNumber = i;
            img.addEventListener("click", hideCAPRow);
            tr.querySelectorAll('td')[1].appendChild(img);
        }
        else if (caps[i][capColNames[j]].constructor === Array) {
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

window.addEventListener('DOMContentLoaded', (event) => {
    colorRows();
    fillCAPTable();
});