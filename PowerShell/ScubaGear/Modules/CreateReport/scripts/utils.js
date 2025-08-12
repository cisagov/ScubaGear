/**
 * Retrieves JSON data derived from the text content of a <script> element with the specified ID.
 * 
 * @param {string} id The ID of the <script> element.
 * @returns {any} The parsed JSON data.
 * @throws {Error} If the element with the specified ID is not found or if the JSON parsing fails.
 */
const getJsonData = (id) => {
    const el = document.getElementById(id);
    if (!el) throw new Error(`Element with id "${id} not found`);
    try {
        return JSON.parse(el.textContent);
    } catch (error) {
        throw new Error(`Failed to parse JSON from element with id "${id}": ${error.message}`);
    }
}

/**
 * Ensures the input value is returned as an array.
 * 
 * @param {any} val The value to normalize.
 * @returns {Array} The normalized array.
 */
const normalizeToArray = (val) => Array.isArray(val) ? val : (val ? [val] : []);

/**
 * Parse .NET JSON date: /Date(1675800895000)/ -> Date
 * 
 * @param {string} val 
 * @returns {Date|null} The parsed date or null if parsing fails.
 */
const parseDotNetDate = (val) => {
    if (typeof val !== "string") return null;
    const match = val.match(/^\/Date\((-?\d+)(?:[+-]\d{4})?\)\/$/);
    if (!match) return null;
    const date = new Date(parseInt(match[1], 10));
    return isNaN(date) ? null : date;
};

/**
 * Checks if Dark Mode session storage variable exists. Creates one if it does not exist.
 * Sets the report's default Dark Mode state using the $DarkMode (JavaScript darkMode) PowerShell variable.
 * @param {boolean} darkMode The default dark mode state.
 * @param {string} pageLocation The page where this function is called.
 */
const mountDarkMode = (darkMode, pageLocation) => {
    try {
        let darkModeCookie = sessionStorage.getItem("darkMode");
        if (darkModeCookie === undefined || darkModeCookie === null) {
            if (darkMode) {
                sessionStorage.setItem("darkMode", 'true');
            }
            else {
                sessionStorage.setItem("darkMode", 'false');
            }
            darkModeCookie = sessionStorage.getItem("darkMode");
        }
        setDarkMode(darkModeCookie);
        document.getElementById('toggle').checked = (darkModeCookie === 'true');
    }
    catch (error) {
        console.error("Error applying dark mode to the " + pageLocation + ": " + error)
    }
}

/**
 * Set the report CSS to light mode or dark mode.
 * @param {string} state true for Dark Mode or false for Light Mode
 */
const setDarkMode = (state) => {
    if (state === 'true') {
        document.getElementsByTagName('html')[0].dataset.theme = "dark";
        document.querySelector("#toggle-text").innerHTML = "Dark Mode";
        sessionStorage.setItem("darkMode", 'true');
    }
    else {
        document.getElementsByTagName('html')[0].dataset.theme = "light";
        document.querySelector("#toggle-text").innerHTML = "Light Mode";
        sessionStorage.setItem("darkMode", 'false');
    }
}

/**
 * Toggles light and dark mode
 */
const toggleDarkMode = () => {
    if (document.getElementById('toggle').checked) {
        setDarkMode('true');
    }
    else {
        setDarkMode('false');
    }
}
