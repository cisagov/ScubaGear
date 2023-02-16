window.addEventListener('DOMContentLoaded', (event) => {
    try {
        let darkModeCookie = sessionStorage.getItem("darkMode");
        if (darkModeCookie === undefined || darkModeCookie === null) {
            if (darkMode) {
                console.log("Hello there v2");
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
        console.error("Error applying dark mode to parent report: " + error)
    }
});