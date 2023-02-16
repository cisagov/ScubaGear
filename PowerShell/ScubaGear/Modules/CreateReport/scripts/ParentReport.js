window.addEventListener('DOMContentLoaded', (event) => {
    try {
        let darkMode = sessionStorage.getItem("darkMode");
        if (darkMode === undefined || darkMode === null) {
            sessionStorage.setItem("darkMode", 'false');
            setDarkMode('false');
        }
        else {
            setDarkMode(darkMode);
            document.getElementById('toggle').checked = (darkMode === 'true');
        }
    }
    catch (error) {
        console.error("Error applying dark mode to parent report: " + error)
    }
});