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
 * For each table present in a report, the function adds scope attributes for columns and rows. 
 */
const applyScopeAttributes = () => {
    try {
        const tables = document.querySelectorAll("table");
        for(let i = 0; i < tables.length; i++) {
            // each table has two children, <colgroup> and <tbody>
            let table = tables[i];
            if(!table) continue;

            const isExpandableTable = (
                table.classList.contains("caps_table") ||
                table.classList.contains("riskyApps_table") ||
                table.classList.contains("riskyThirdPartySPs_table")
            );

            if (isExpandableTable) {
                const thead = table.querySelector("thead");
                const tbody = table.querySelector("tbody");
                if (!thead || !tbody) continue;

                /**
                 * <thead> contains contains a single <tr> with <th> elements, label each with scope="col"
                 * 
                 * <tbody> contains multiple <tr>, each <tr> represents a row.
                 * For each <tr>, the first <td> should be labeled as scope="row", leave the rest
                 */
                const cols = thead.querySelectorAll("th");
                cols.forEach(col => col.setAttribute("scope", "col"));

                const rows = tbody.querySelectorAll("tr");
                rows.forEach(row => {
                    const td = row.querySelectorAll("td");
                    if (td.length > 0) td[0].setAttribute("scope", "row");
                })
            }
            else {
                const tbody = table.querySelector("tbody");
                if (!tbody || !tbody.children || tbody.children.length === 0) continue;

                /**
                * the first <tr> in <tbody> represents columns. Label each nested <th> as scope="col"
                * 
                * second <tr> + ... are the rows
                * for each <tr>, the first <td> should be labeled as scope="row", leave the rest
                */
                const colRow = tbody.children[0];
                const cols = colRow.querySelectorAll("th");
                cols.forEach(col => col.setAttribute("scope", "col"));

                for (let tr = 1; tr < tbody.children.length; tr++) {
                    const td = tbody.children[tr].querySelectorAll("td");
                    if (td.length > 0) td[0].setAttribute("scope", "row");
                }
            }
        }
    }
    catch (error) {
        console.error(`Error in applyScopeAttributes, ${error}`);
    }
}