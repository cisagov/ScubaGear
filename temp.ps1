
$ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
$OutputFolder = $ReportFolders[0]
$OutputFolder

$Jsonfile = ".\$OutputFolder\TestResults.json"
$Jsonfile