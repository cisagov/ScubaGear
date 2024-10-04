# Reports

When ScubaGear runs, it creates a new time-stamped subdirectory wherein it will write all of the results of its testing. What follows are the default names for the various outputs, which can be changed using the corresponding [parameters](../configuration/parameters.md).

| Result                       | Purpose   |
|------------------------------|-----------|
| `IndividualReports`          | This directory contains the detailed reports for each product tested. |
| `BaselineReports.html`       | This HTML file is a summary of the detailed reports. By default, this file is automatically opened in a web browser after running ScubaGear. |
| `ProvideSettingsExport.json` | This JSON file contains all of the information that ScubaGear extracted from the products.  A highly-motivated admin might find this useful for understanding how ScubaGear arrived at its results. Only present if ScubaGear is run with the `KeepIndividualJson` flag; if run without the `KeepIndividualJSON` parameter, the contents of this file will be merged into the ScubaResults.json file. |
| `ScubaResults.json`           | This JSON file encapsulates all ScubaGear output in a format that is automatically parsed by a downstream system. It contains metadata about the run and the tenant, summary counts of the test results, the test results, and the raw provider output. Not present if ScubaGear is run with the `KeepIndividualJSON` flag. |
| `ScubaResults.csv`            | This CSV file contains the test results in a format that could be automatically parsed by a downstream system. Note that this CSV file only contains the results (i.e., the control ID, requirement string, etc.). It does not contain all data contained in the HTML or JSON versions of the output (i.e., the metadata, summary counts, or raw provider output) due to the limitations of CSV files. |
| `ActionPlan.csv`            | This CSV file contains the test results in a format that could be automatically parsed by a downstream system, filtered down to just failing "SHALL" controls. For each failing test, it includes fields where users can document reasons for failures and timelines for remediation, if they so choose. |

You can learn more about setting parameters on the [parameters](../configuration/parameters.md) page.
