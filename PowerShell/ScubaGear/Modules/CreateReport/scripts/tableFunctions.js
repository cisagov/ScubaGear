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
            let tbody = tables[i].querySelector("tbody");
            if(!tbody) throw new Error(
                `Invalid HTML structure, <table id='${tables[i].getAttribute("id")}'> does not have a <tbody> tag.`
            );
            
            /**
             * the first <tr> in <tbody> represents columns. Label each nested <th> as scope="col"
             * 
             * second <tr> + ... are the rows
             * for each <tr>, the first <td> should be labeled as scope="row", leave the rest
             */
            let cols, rows;
            if(tbody.children && tbody.children.length > 1) {
                cols = tbody.children[0].querySelectorAll("th");
                for(let th = 0; th < cols.length; th++) {
                    cols[th].setAttribute("scope", "col");
                }

                // change location of scope="row" if necessary (may have to adjust for structure of license info?)
                let trIdx = (tables[i].classList.contains("caps_table")) ? 1 : 0;

                // skip column <tr>; for each remaining <tr> set the scope 
                rows = tbody.children;
                for(let tr = 1; tr < rows.length; tr++) {
                    rows[tr].querySelectorAll("td")[trIdx].setAttribute("scope", "row");
                }
            }
            else throw new Error(
                `Unable to apply scope attributes to columns/rows, 
                <tbody> of <table id='${tables[i].getAttribute("id")}'> does not contain children or has no rows.`
            );
        }
    }
    catch (error) {
        console.error(`Error in applyScopeAttributes, ${error}`);
    }
}