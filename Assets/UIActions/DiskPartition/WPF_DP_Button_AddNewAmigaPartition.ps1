$WPF_DP_Button_AddNewAmigaPartition.add_click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    # $AmigaDiskName = 'WPF_DP_Partition_MBR_2_AmigaDisk'
   
    if ($WPF_DP_AddNewAmigaPartition_DropDown.SelectedItem -eq 'At end of disk'){
        $AddType = 'AtEnd'     
        $AmigaDiskName = "$($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName)_AmigaDisk"
    }
    elseif ($WPF_DP_AddNewAmigaPartition_DropDown.SelectedItem -eq 'Left of selected partition'){
        $AddType = 'Left'   
        $AmigaDiskName = ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.Substring(0,($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.IndexOf('_AmigaDisk_Partition_')+10))) 
    }
    elseif ($WPF_DP_AddNewAmigaPartition_DropDown.SelectedItem -eq 'Right of selected partition'){
        $AddType = 'Right'  
        $AmigaDiskName = ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.Substring(0,($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.IndexOf('_AmigaDisk_Partition_')+10))) 
    }
    
    if (($AddType -ne 'AtEnd') -and (-not $Script:GUICurrentStatus.SelectedAmigaPartition)){
        $null = Show-WarningorError -Msg_Header 'No Partition Selected' -Msg_Body 'You must select a partition!' -BoxTypeError -ButtonType_OK
        return
    } 
    
    Set-AmigaDiskSizeOverhangPixels -AmigaDisk $AmigaDiskName
    
    $CurrentNumberofPartitionsonAmigaDisk = (@($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object { $_.PartitionName -match $AmigaDiskName })).count
    
    if ($CurrentNumberofPartitionsonAmigaDisk -eq $Script:Settings.AmigaPartitionsperDiskMaximum){
        $null = Show-WarningorError -Msg_Header "Exceeded maximum number of partitions" -Msg_Body "You have $($Script:Settings.AmigaPartitionsperDiskMaximum) partitions on this disk! No more partitions can be added." -BoxTypeError -ButtonType_OK
        return
    }

    if (-not ($CurrentNumberofPartitionsonAmigaDisk) -or $CurrentNumberofPartitionsonAmigaDisk -eq 0){
        $CanAddPartition = $true
        $EmptyAmigaDisk = $true
    }
    else {
        $CanAddPartition = (Get-Variable -Name $AmigaDiskName).value.CanAddPartition
        $EmptyAmigaDisk = $false
        If (($AddType -eq "AtEnd") -and (-not ($Script:GUICurrentStatus.SelectedAmigaPartition))){
            $PartitionNexttotouse = ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $AmigaDiskName}).PartitionName | Select-Object -Last 1
        }
        else {
            $PartitionNexttotouse = $Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName
        }
    }
    
    if ($CanAddPartition -eq $false) {
        $null = Show-WarningorError -Msg_Header 'Imported Partition Selected' -Msg_Body 'You cannot add partitions to an imported partition!' -BoxTypeError -ButtonType_OK
        return        
    }

    # Write-debug "Addtype is: $Addtype DiskName is: $AmigaDiskName Allows addition of partitions: $CanAddPartition" 
        
    if ($EmptyAmigaDisk -eq $true){
        $AvailableFreeSpace = (Get-Variable -name $AmigaDiskName).value.DiskSizeBytes
        #Write-debug "Empty Disk - Available free space is: $AvailableFreeSpace"
    }
    else {
        $AvailableFreeSpace = (Get-AmigaDiskFreeSpace -Disk (Get-Variable -Name $AmigaDiskName).Value -Position $AddType -PartitionNameNextto $PartitionNexttotouse)
        #Write-debug "Available free space is: $AvailableFreeSpace "
    }
    $AvailableFreeSpace = (Get-AmigaNearestSizeBytes -RoundDown $AvailableFreeSpace)
    #Write-debug "Available free space rounded down is: $AvailableFreeSpace"

    if ($AvailableFreeSpace -gt $Script:SDCardMinimumsandMaximums.PFS3Maximum) {
        $AvailableFreeSpace = $Script:SDCardMinimumsandMaximums.PFS3Maximum
    }

    $MinimumFreeSpace = (Get-AmigaNearestSizeBytes -RoundDown $Script:SDCardMinimumsandMaximums.PFS3Minimum)
    if ($AvailableFreeSpace -lt $MinimumFreeSpace){
        $null = Show-WarningorError -Msg_Header 'No Free Space' -Msg_Body 'Insufficient freespace to create partition!' -BoxTypeError -ButtonType_OK
    }
    else {

        $SpacetoUse = Get-NewPartitionSize -DefaultScale 'MiB' -MaximumSizeBytes $AvailableFreeSpace -MinimumSizeBytes $MinimumFreeSpace
        if ($SpacetoUse){
            $WorkDefaultValues = Get-InputCSVs -Diskdefaults | Where-Object {$_.Type -eq "Amiga" -and $_.Disk -eq 'Work'}
            
            $DeviceandVolumeNametoUse = (Get-DeviceandVolumeNametoUse)
    
            #Write-Host "$AmigaDiskName $AddType $PartitionNexttotouse"

            Add-GUIPartitiontoAmigaDisk -AmigaDiskName $AmigaDiskName -AddType $AddType -DeviceName $DeviceandVolumeNametoUse.DeviceName -VolumeName $DeviceandVolumeNametoUse.VolumeName -PartitionNameNextto $PartitionNexttotouse -SizeBytes (Get-AmigaNearestSizeBytes -RoundDown -SizeBytes $SpacetoUse) -Buffers $WorkDefaultValues.Buffers -DosType $WorkDefaultValues.DosType -NoMount $WorkDefaultValues.NoMountFlag -Bootable $WorkDefaultValues.BootableFlag -Priority ([int]$WorkDefaultValues.Priority) -MaxTransfer $WorkDefaultValues.MaxTransfer -Mask $WorkDefaultValues.Mask
    
            Update-UI -DiskPartitionWindow

            Set-AmigaDiskSizeOverhangPixels -AmigaDisk $AmigaDiskName
        }

        else {
            return
        }
        
    }
    
})



