# Find copy books with the *.cpy extension in the source code directory
$cpyFilesInfo = Get-ChildItem -Path EOCF -File -Recurse -Filter '*.cpy'
Write-Output "$($cpyFilesInfo.Count) files with extension ""*.cpy"" found"

$duplicatedFileNamesGroupInfoObjects = $cpyFilesInfo | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
Write-Output "$($duplicatedFileNamesGroupInfoObjects.Count) duplicated file names found"

# Log names that appear more than 2 times
$a = $duplicatedFileNamesGroupInfoObjects | Where-Object { $_.Count -gt 2 }
if ($a.Count -gt 0) {
    Write-Output ""
    Write-Output "Some file names appear more than twice..."
    Write-Output "  File name: $($a.Name)"
    foreach ($name in $a.Group) {
        Write-Output "    $($name)"
    }
    Write-Output ""
}

if (($null -ne $duplicatedFileNamesGroupInfoObjects) -and ($duplicatedFileNamesGroupInfoObjects.Count -gt 0)) {
    # Select the groups of duplicated files so that we can rename the duplicates
    $duplicatedFileNamesGroups = $duplicatedFileNamesGroupInfoObjects.Group

    # Only files in the COPYPROC directory should remain part of the analysis. All others are renamed
    # The changed file extension must not be part of the Sonar analysis (left out of Cobol source and copybook extensions)
    $filesToRename = $duplicatedFileNamesGroups | Where-Object { $_.Directory.Name -ne "COPYPROC" }
    Write-Output "$($filesToRename.Count) files will be renamed"
    Write-Output "Changing file extensions..."

    foreach ($file in $filesToRename) {
        try {
            $file | Rename-Item -NewName { $_.Name -replace '.cpy', '.cpyx' } -Verbose -ErrorAction Stop
        }
        catch {
            Write-Output "Failed to rename file $file"
            $_.Exception
            Exit 1
        }
    }
    Write-Output "File extensions changed"
}
else {
    Write-Output "No file extensions changed."
}
