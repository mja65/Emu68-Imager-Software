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
    $LocationstoCheck += $Script:Settings.TempFolder

    write-informationMessage -Message "Checking for existence of default folders" -NewLineAfter
    
    foreach ($PathtoCheck in $LocationstoCheck) {
        if (-not(Test-Path $PathtoCheck -PathType Container)){
            write-informationMessage -Message "Folder $(Split-Path -Path $PathtoCheck -Leaf) does not exist! Creating folder."
            $null = New-Item ($PathtoCheck) -ItemType Directory -Force
        } 
    }
       
    write-informationMessage -Message "Checking for existence of default folders - Complete" -NewLineAfter

}
