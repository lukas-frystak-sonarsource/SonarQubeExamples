# Find files which had their extension changed
$filesWithChangedNamesToRollBack = Get-ChildItem -Path EOCF -File -Recurse -Filter '*.cpyx'
Write-Output "$($filesWithChangedNamesToRollBack.Count) files found with changed extension that will be rolled back"

if (($null -ne $filesWithChangedNamesToRollBack) -and ($filesWithChangedNamesToRollBack.Count -gt 0)) {
    $filesWithChangedNamesToRollBack | Rename-Item -NewName { $_.Name -replace '.cpyx', '.cpy' } -Verbose
}
else {
    Write-Output "No files to roll back, nothing was renamed.\"
}
