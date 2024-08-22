# Reports

When ScubaGear runs, it creates a new time-stamped subdirectory wherein it will write all of the results of its testing. What follows are the default names for the various outputs, which can be changed using the corresponding [parameters](../configuration/parameters.md).

| Result                       | Purpose   |
|------------------------------|-----------|
| `IndividualReports`          | This directory contains the detailed reports for each product tested. |
| `BaselineReports.html`       | This HTML file is a summary of the detailed reports. By default, this file is automatically opened in a web browser after running ScubaGear. |
| `ProvideSettingsExport.json` | This JSON file contains all of the information that ScubaGear extracted from the products.  A highly-motivated admin might find this useful for understanding how ScubaGear arrived at its results. Only present if ScubaGear is run without the `MergeJson` flag; if run with the `MergeJson` parameter, the contents of this file will be merged into the ScubaResults.json file. |
| `ScubaResults.csv`            | This CSV file contains the test results in a format can could be automatically parsed by a downstream system. Only present if ScubaGear is run with the `MergeJson` flag. |
| `ScubaResults.json`           | This JSON file encapsulates all ScubaGear output in a format can could be automatically parsed by a downstream system. It contains metadata about the run and the tenant, summary counts of the test results, the test results, and the raw provider output. Only present if ScubaGear is run with the `MergeJson` flag. |

You can learn more about setting parameters on the [parameters](../configuration/parameters.md) page.
