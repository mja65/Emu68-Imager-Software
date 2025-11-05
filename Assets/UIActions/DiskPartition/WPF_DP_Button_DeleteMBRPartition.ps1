$WPF_DP_Button_DeleteMBRPartition.add_click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    # $Script:GUICurrentStatus.SelectedGPTMBRPartition = 'WPF_DP_Partition_MBR_2'
    if ($Script:GUICurrentStatus.SelectedGPTMBRPartition){
        If (($Script:GUIActions.InstallOSFiles -eq $true) -and ($Script:GUICurrentStatus.SelectedGPTMBRPartition.DefaultGPTMBRPartition -eq $true) -and ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSubType -eq 'ID76')){

$MessageBody = 
@"
You have selected the default ID 0x76 Amiga Partition for deletion! If you really want to do this you will not be installing ANY OS files! 

All currently selected Kickstart ROMs, Workbench install files, and user selected packages will be unselected. If you change your mind after deleting and want to create an image with an installed OS you will need to you will need to reset the disk and reperform those steps. 

Press OK to continue otherwise cancel
"@   

            if ((Show-WarningorError -Msg_Header 'Deleting Default Amiga Partition' -BoxTypeWarning -ButtonType_OKCancel  -Msg_Body $MessageBody) -eq 'Cancel'){
                return
            }
            else {
                $DeleteDefaultAmigaPartition = $true
            }
       
        }

        if ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSubType -eq 'ID76'){
            $DeleteUnderlyingAmigaPartitions = $true
        }
        else {
            $DeleteUnderlyingAmigaPartitions = $false
        }


        if ((Remove-MBRGUIPartition -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition) -eq $false){
            Show-WarningorError -Msg_Header 'Cannot Delete Partition' -Msg_Body 'MBR Partition is default partition. Cannot delete.' -BoxTypeError -ButtonType_OK
            return
        }
    
        if ($DeleteUnderlyingAmigaPartitions -eq $true){
            $Script:GUICurrentStatus.SelectedAmigaPartition = $null
            $ListofPartitionstoDelete = ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $Script:GUICurrentStatus.SelectedGPTMBRPartition} ).PartitionName
            if ($ListofPartitionstoDelete){
                $ListofPartitionstoDelete  | ForEach-Object {
                    Remove-Variable -Scope Script -Name $_
                }
        
                Remove-Variable -Scope Script -Name  "$($Script:GUICurrentStatus.SelectedGPTMBRPartition)_AmigaDisk"
            }
        }

        if ($DeleteDefaultAmigaPartition -eq $true){
            $Script:GUIActions.InstallOSFiles = $false
            $Script:GUIActions.InstallMediaLocation = $null
            $Script:GUIActions.ROMLocation = $null
            $Script:GUIActions.KickstartVersiontoUse = $null
            $Script:GUIActions.KickstartVersiontoUseFriendlyName = $null
            $Script:GUIActions.OSInstallMediaType = $null
            $Script:GUIActions.FoundInstallMediatoUse = $null
            $Script:GUIActions.FoundKickstarttoUse = $null
        }

        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null

        Update-UI -DiskPartitionWindow -HighlightSelectedPartitions
        
    }
    else {
        Show-WarningorError -Msg_Header 'Cannot Delete Partition' -Msg_Body "No partititon is selected!" -BoxTypeError -ButtonType_OK
        return
    }
})
