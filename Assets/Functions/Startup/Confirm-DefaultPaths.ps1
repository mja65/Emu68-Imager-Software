function Confirm-DefaultPaths {
    param (
     
    )
    
    $LocationstoCheck = @()

    $LocationstoCheck += $Script:Settings.DefaultSettingsLocation 
    $LocationstoCheck += $Script:Settings.DefaultOutputImageLocation 
    $LocationstoCheck += $Script:Settings.RoadshowFilesLocation
    $LocationstoCheck += $Script:Settings.MiamiFilesLocation 
    $LocationstoCheck += $Script:Settings.DefaultInstallMediaLocation
    $LocationstoCheck += $Script:Settings.DefaultImportLocation 
    $LocationstoCheck += $Script:Settings.DefaultROMLocation
    $LocationstoCheck += $Script:Settings.DownloadedFileSystems
    $LocationstoCheck += $Script:Settings.DefaultAmigaFileSystemLocation
    $LocationstoCheck += $Script:Settings.InputFiles.Path
    $LocationstoCheck += $Script:Settings.TempFolder

    Write-InformationMessage "Checking for existence of default folders"
    Write-InformationMessage ""
    
    foreach ($PathtoCheck in $LocationstoCheck) {
        if (-not(Test-Path $PathtoCheck -PathType Container)){
            Write-InformationMessage "Folder $(Split-Path -Path $PathtoCheck -Leaf) does not exist! Creating folder."
            $null = New-Item ($PathtoCheck) -ItemType Directory -Force
        } 
    }

    Write-InformationMessage "Checking for temporary files from previous use and removing"
    Write-InformationMessage ""

    $tempFolder = [System.IO.Path]::GetFullPath($Script:Settings.TempFolder)
    $webPackagesPath = Join-Path $tempFolder "WebPackagesDownload"

    $cleanupScript = {
        # Remove all items in TempFolder except "WebPackagesDownload"
        Get-ChildItem -Path $using:tempFolder | Where-Object { $_.Name -ne "WebPackagesDownload" } | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    
        # Remove subfolders within "WebPackagesDownload" if it exists
        if (Test-Path $using:webPackagesPath) {
            Get-ChildItem -Path $using:webPackagesPath | Where-Object { $_.PSIsContainer } | ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
        
    Show-SpinnerWhileDeleting -ScriptBlock $cleanupScript 
       
    Write-InformationMessage "Checking for existence of default folders - Complete"
    Write-InformationMessage ""

}
