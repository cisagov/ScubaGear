const mountDarkMode = (errorLocation) => {
    try {
        let darkModeCookie = sessionStorage.getItem("darkMode");
        if (darkModeCookie === undefined || darkModeCookie === null) {
            if (darkMode) {
                sessionStorage.setItem("darkMode", 'true');
            }
            else {
                sessionStorage.setItem("darkMode", 'false');
            }
        }
        darkModeCookie = sessionStorage.getItem("darkMode");
        setDarkMode(darkModeCookie);
        document.getElementById('toggle').checked = (darkModeCookie === 'true');
    }
    catch (error) {
        console.error("Error applying dark mode to the " + errorLocation + ": " + error)
    }
}

/**
 * Set light and dark mode
 */
const setDarkMode = (state) => {
    if (state === 'true') {
        document.getElementsByTagName('html')[0].dataset.theme = "dark";
        document.querySelector("#toggle-text").innerHTML = "Dark mode";
        sessionStorage.setItem("darkMode", 'true');
    }
    else {
        document.getElementsByTagName('html')[0].dataset.theme = "light";
        document.querySelector("#toggle-text").innerHTML = "Light mode";
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
