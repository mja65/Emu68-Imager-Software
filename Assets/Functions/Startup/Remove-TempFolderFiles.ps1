    function Remove-TempFolderFiles {
    param (
     
    )
    write-informationMessage -Message "Checking for temporary files from previous use and removing" -NewLineAfter

    $TempFolder = [System.IO.Path]::GetFullPath($Script:Settings.TempFolder)
    $WebPackagesPath = [System.IO.Path]::GetFullPath($Script:Settings.WebPackagesDownloadLocation)

    $CleanupScript = {
        # Remove all items in TempFolder except "WebPackagesDownload"
        Get-ChildItem -Path $using:TempFolder | Where-Object { $_.Name -ne "WebPackagesDownload" } | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    
        # Remove subfolders within "WebPackagesDownload" if it exists
        if (Test-Path $using:WebPackagesPath) {
            Get-ChildItem -Path $using:WebPackagesPath -Directory | ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
        
    Show-SpinnerWhileDeleting -ScriptBlock $cleanupScript 

    write-informationMessage -Message "Removal of temporary files complete " 
}