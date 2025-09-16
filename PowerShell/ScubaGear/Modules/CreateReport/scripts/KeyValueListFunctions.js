/**
 * Filter an array of objects based on the specific search term.
 * 
 * @param {Array} arr - Array of objects to filter. 
 * @param {string} term - Search term to filter items by.
 * @returns {Array} - Filtered array of objects.
 */
const filterBySearch = (arr, term) => {
    if (!term) return arr;
    const lower = term.toLowerCase();

    return arr.filter(o => {
        if (!o || typeof o !== "object") return false;

        return Object.values(o).some(v => String(v).toLowerCase().includes(lower));
    });
};

/**
 * Determine if a credential is active, expired, etc. based on its start and end times.
 * 
 * @param {object} cred - credential object contains KeyId, DisplayName, StartDateTime, EndDateTime, and IsFromApplication.
 * @returns {string} "Active", "Expired", "Inactive", or "Unknown".
 */
const getCredentialState = (cred) => {
    if (!cred || typeof cred !== "object") return "Unknown";
    const start = parseDotNetDate(cred.StartDateTime);
    const end = parseDotNetDate(cred.EndDateTime);
    const now = new Date();

    if (start && end) {
        if (now < start) return "Inactive";
        if (now > end)   return "Expired";

        return "Active";
    }

    if (end && now > end) return "Expired";

    return "Active";
};

/**
 * Group permissions based on the specified group key.
 * Perform some formatting to convert values like false/true to Risky/Not risky (for example).
 * 
 * @param {Array} data - Permission data to be grouped.
 * @param {string} groupKey - "Permissions" or "Credentials".
 * @returns {object} - Map of grouped permissions.
 */
const groupPermissions = (data, groupKey) => {
    if (groupKey === "none") return { All: data };
    const map = {};

    data.forEach(obj => {
        let keyVal = obj[groupKey];
        if (groupKey === "IsAdminConsented" || groupKey === "IsRisky") {
            if (keyVal === true) keyVal = "Admin consented";
            else if (keyVal === false) keyVal = "Not admin consented";
            else keyVal = "Unknown";
        }
        else if (groupKey === "IsRisky") {
            if (keyVal === true) keyVal = "Risky";
            else if (keyVal === false) keyVal = "Not risky";
            else keyVal = "Unknown";
        }
        else if (keyVal === "" || keyVal === null || keyVal === undefined) {
            keyVal = "Unknown";
        }

        if (!map[keyVal]) map[keyVal] = [];
        map[keyVal].push(obj);
    });

    return map;
};

/**
 * Render a single object's key/value pairs as a list item.
 * 
 * @param {object} obj - Object containing key/value pairs to render.
 * @returns {HTMLElement} - DOM node of the rendered list item.
 */
const renderObject = (obj) => {
    const li = document.createElement("li");
    li.classList.add("kv-item");

    Object.entries(obj).forEach(([key, value], idx, arr) => {
        const strong = document.createElement("strong");
        strong.textContent = `${key}:`;
        li.appendChild(strong);
        let content = value;

        if (typeof value === "string" && (key === "StartDateTime" || key === "EndDateTime")) {
            const date = parseDotNetDate(value);
            content = date ? date.toLocaleString() : value;
        }

        li.appendChild(document.createTextNode(` ${String(content)}`));
        if (idx < arr.length - 1) li.appendChild(document.createElement("br"));
    });

    return li;
};

/**
 * Render the group section which contains a specified title (Application vs. Delegated for example)
 * and the total number of list items in that group.
 * 
 * This component also renders an unordered list of the items belonging to a respective group.
 * 
 * @param {string} title - Title of the group section.
 * @param {Array} itemsArr - Array of objects belonging to that group.
 * @param {HTMLElement} resultList - DOM node where the filtered results will be rendered.
 */
const renderGroupSection = (title, itemsArr, resultList) => {
    const section = document.createElement("section");
    section.classList.add("kv-group");

    const h4 = document.createElement("h4");
    h4.textContent = `${title} (${itemsArr.length})`;
    section.appendChild(h4);

    const ul = document.createElement("ul");
    itemsArr.forEach(o => ul.appendChild(renderObject(o)));
    section.appendChild(ul);
    resultList.appendChild(section);
};

/**
 * Render a table data cell's information after filtering options have been applied.
 * 
 * @param {Array} items - The metadata that belonging to a single table data cell.
 * @param {object} state - Current state of user input controls (search term, group by option).
 * @param {HTMLElement} resultList - DOM node where the filtered results will be rendered.
 */
const renderFilteredList = (items, state, resultList) => {
    resultList.textContent = "";
    const filtered = filterBySearch(items, state.search);

    if (state.dataType === "Credentials") {
        const active  = filtered.filter(c => getCredentialState(c) === "Active");
        const expired = filtered.filter(c => getCredentialState(c) === "Expired");
        renderGroupSection("Active", active, resultList);
        renderGroupSection("Expired", expired, resultList);
        return;
    }

    if (state.dataType === "Permissions") {
        const groups = groupPermissions(filtered, state.groupBy);
        Object.entries(groups).forEach(([name, arr]) => renderGroupSection(name, arr, resultList));
        return;
    }

    renderGroupSection("All", filtered, resultList);
};

/**
 * Stores all logic for search/filter operations and rendering a table data cell's key/value pairs
 * based on selected user input.
 * 
 * @param {Array} listItems - The metadata that belongs to a single table data cell.
 * @param {string} dataType - Either "Credentials" or "Permissions".
 * @returns {HTMLElement} - DOM node of control inputs and list of a table data cell's key/value pairs.
 */
const renderAdvancedKeyValueList = (listItems, dataType) => {
    const wrapper = document.createElement("div");
    wrapper.classList.add("kv-advanced");

    const controls = document.createElement("div");
    controls.classList.add("kv-controls");
    wrapper.appendChild(controls);

    const searchInput = document.createElement("input");
    searchInput.type = "search";
    searchInput.id = "modal-search";
    searchInput.placeholder = "Search...";
    controls.appendChild(searchInput);

    // The option to group by is only present for permissions. Credentials only has "active"/"expired" fields.
    let groupSelect = null;
    if (dataType === "Permissions") {
        const selectLabel = document.createElement("label");
        selectLabel.htmlFor = "modal-group-by";
        selectLabel.textContent = " Group by";
        controls.appendChild(selectLabel);  

        groupSelect = document.createElement("select");
        groupSelect.id = "modal-group-by"
        const groupOptions = [
            { value: "none", label: "No grouping" },
            { value: "RoleType", label: "Role type" },
            { value: "IsAdminConsented", label: "Admin consent" },
            { value: "IsRisky", label: "Risk" }
        ];

        groupOptions.forEach(o => {
            const option = document.createElement("option");
            option.value = o.value;
            option.textContent = o.label;
            groupSelect.appendChild(option);
        });
        controls.appendChild(groupSelect);
    }

    const state = {
        search: "",
        groupBy: "none",
        dataType: dataType,
    };

    const resultList = document.createElement("div");
    resultList.classList.add("kv-results");
    wrapper.appendChild(resultList);

    searchInput.addEventListener("input", e => {
        state.search = e.target.value;
        renderFilteredList(listItems, state, resultList);
    });

    if (groupSelect) {
        groupSelect.addEventListener("change", e => {
            state.groupBy = e.target.value;
            renderFilteredList(listItems, state, resultList);
        });
    }

    renderFilteredList(listItems, state, resultList);
    return wrapper;
};