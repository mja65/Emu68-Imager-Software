$WPF_DP_Button_ImportFiles.add_click({
            If ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    else {
        $Script:GUICurrentStatus.FileBoxOpen = $true
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
            $PartitionSizeByes = $Script:GUICurrentStatus.SelectedAmigaPartition.PartitionSizeBytes 
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.DefaultAmigaWorkbenchPartition -eq $true){
               $Script:GUICurrentStatus.FileBoxOpen = $false
                Show-WarningorError -Msg_Header 'Default Workbench Partition Selected' -Msg_Body 'Cannot transfer files to the default Workbench partition!' -BoxTypeError -ButtonType_OK
            }
            elseif ($Script:GUICurrentStatus.SelectedAmigaPartition.CanImportFiles -eq $false){
                $Script:GUICurrentStatus.FileBoxOpen = $false
                Show-WarningorError -Msg_Header 'Imported Partition Selected' -Msg_Body 'Cannot transfer files to the this partition!' -BoxTypeError -ButtonType_OK
            }
            else {
                $PathtoPopulate = Get-FolderPath -Message 'Select path to files to import' -InitialDirectory ([System.IO.Path]::GetFullPath($Script:Settings.DefaultImportLocation)) 
                if ($PathtoPopulate){
                    $Separator = [System.IO.Path]::DirectorySeparatorChar
                    $ReservedPaths = @(
                        $Script:Settings.MiamiFilesLocation
                        $Script:Settings.RoadshowFilesLocation
                        $Script:Settings.DefaultOutputImageLocation
                        $Script:Settings.DefaultInstallMediaLocation
                        $Script:Settings.DefaultROMLocation
                        $Script:Settings.DownloadedFileSystems
                    ) | ForEach-Object { [System.IO.Path]::GetFullPath($_).TrimEnd($Separator) + $Separator }
                        
                    $PathtoCheck = [System.IO.Path]::GetFullPath($PathtoPopulate).TrimEnd($Separator) + $Separator

                    if ($ReservedPaths | Where-Object {$PathtoCheck.StartsWith($_) }) {
                        $CannotUseFolder = $true
                        $Script:GUICurrentStatus.FileBoxOpen = $false
                        Show-WarningorError -Msg_Header 'Reserved Folder Location' -Msg_Body 'Cannot import files from this folder Location!' -BoxTypeError -ButtonType_OK
                    } 
                    
                    $SpaceofFolderBytes = (Get-ChildItem -Path $PathtoPopulate -recurse | Measure-Object -Property Length -Sum).Sum
                    if ($SpaceofFolderBytes -gt $PartitionSizeByes){
                        $CannotUseFolder = $true
                        $Script:GUICurrentStatus.FileBoxOpen = $false
                        Show-WarningorError -Msg_Header 'Insufficient Space' -Msg_Body 'Insufficient space on partition for files!' -BoxTypeError -ButtonType_OK
                    }
                    If ($CannotUseFolder -ne $true) {
                        $Script:GUICurrentStatus.SelectedAmigaPartition.ImportedFilesPath = $PathtoPopulate 
                        $Script:GUICurrentStatus.SelectedAmigaPartition.ImportedFilesSpaceBytes = $SpaceofFolderBytes
                        $Script:GUICurrentStatus.FileBoxOpen = $false
                        Update-UI -UpdateInputBoxes
                    }
                }
                else {
                    $Script:GUICurrentStatus.FileBoxOpen = $false
                    return
                }
    
            }
        }
        else{
            $Script:GUICurrentStatus.FileBoxOpen = $false
            Show-WarningorError -Msg_Header 'No Partition Selected' -Msg_Body 'Cannot transfer files without selecting partition!' -BoxTypeError -ButtonType_OK
        }

    }
})

