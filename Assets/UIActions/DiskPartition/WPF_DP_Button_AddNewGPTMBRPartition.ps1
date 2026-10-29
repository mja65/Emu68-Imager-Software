$WPF_DP_Button_AddNewGPTMBRPartition.add_click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    if ($WPF_DP_AddNewGPTMBRPartition_DropDown.SelectedItem -eq 'At end of disk'){
        $AddType = 'AtEnd'        
    }
    elseif ($WPF_DP_AddNewGPTMBRPartition_DropDown.SelectedItem -eq 'Left of selected partition'){
        $AddType= 'Left'   
    }
    elseif ($WPF_DP_AddNewGPTMBRPartition_DropDown.SelectedItem -eq 'Right of selected partition'){
        $AddType= 'Right'   
    }
    
    $PartitionTypeDetails = (Get-InputFileCSV -CSV 'PartitionTypes').where({ $_.DiskType -eq $Script:GUIActions.DiskType -and $_.UserCanAdd -eq $true})
    $PartitionSubtypetouse = ($PartitionTypeDetails.Where({ $_.PartitionLabelGUI -eq $WPF_DP_AddNewGPTMBRPartition_Type_DropDown.SelectedItem  })).PartitionCodeEmu68Image

    # Write-debug  "$AddType $($Script:GUICurrentStatus.SelectedGPTMBRPartition)"
    if (($AddType -ne 'AtEnd') -and (-not $Script:GUICurrentStatus.SelectedGPTMBRPartition)){
        # Write-debug "$($Script:GUICurrentStatus.SelectedGPTMBRPartition)"
        $null = Show-WarningorError -Msg_Header 'No Partition Selected' -Msg_Body 'You must select a partition!' -BoxTypeError -ButtonType_OK
    } 
    $DiskTypeDetails = (Get-InputFileCSV -CSV 'DiskTypes').where({ $_.DiskType -eq $Script:GUIActions.DiskType }) 
    else {
        if (($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries).count -eq $DiskTypeDetails.MaximumNumberPartitions){
            $null = Show-WarningorError -Msg_Header "Maximum Number of Partitions" -Msg_Body "You have reached the maximum number of partitions allowed ($($DiskTypeDetails.MaximumNumberPartitions)). Cannot create partition!" -BoxTypeError -ButtonType_OK
        }
        else {
            $PartitionTypeDetails = Get-GPTMBRPartitionDefaultDetails -DiskType $Script:GUIActions.DiskType -PartitionType $PartitionSubtypetouse 
            $MinimumRequiredSpace = $PartitionTypeDetails.MinimumSizeBytes
            $AvailableSpace = (Get-MBRDiskFreeSpace -Disk $WPF_DP_Disk_GPTMBR -Position $AddType -PartitionNameNextto $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName)
            $AvailableSpace = (Get-MBRNearestSizeBytes -Rounddown $AvailableSpace)
            $MinimumRequiredSpace = (Get-MBRNearestSizeBytes -Roundup $MinimumRequiredSpace)
            if ($AvailableSpace -lt $MinimumRequiredSpace){
                $null = Show-WarningorError -Msg_Header 'No Free Space' -Msg_Body 'Insufficient freespace to create partition!' -BoxTypeError -ButtonType_OK
            }
            else {
                $SpacetoUse = Get-NewPartitionSize -DefaultScale 'GiB' -MaximumSizeBytes $AvailableSpace -MinimumSizeBytes $MinimumRequiredSpace
                if ($SpacetoUse){
                    # Write-debug "Adding Partition with subtype:$PartitionSubtypetouse Addtype:$AddType Size:$(Get-MBRNearestSizeBytes -RoundDown -SizeBytes $SpacetoUse)"
                    Add-GUIPartitiontoGPTMBRDisk -PartitionSubType $PartitionSubtypetouse -PartitionType $Script:GUIActions.DiskType -PartitionNameNextto $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName -AddType $AddType -SizeBytes (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $SpacetoUse) 
                }
                else {
                    return
                }

            }
        }
    }
})

