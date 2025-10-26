function Set-GUIPartitionNewSize {
    param (
        [Switch]$ResizeBytes,
        [Switch]$ResizePixels,
        $Partition,
        $ActiontoPerform,
        $PartitionType,
        $SizeBytes,
        $SizePixelstoChange
    )
    
    # $Partition = $WPF_DP_Partition_MBR_2
    # $Partition = $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_2
    # $SizeBytes = 536870912
    # $ActiontoPerform = 'MBR_ResizeFromRight'
    # $PartitionType = 'MBR'
   
    #Write-debug "Function Set-GUIPartitionNewSize Partition:$Partition PartitionType:$PartitionType SizeBytes:$SizeBytes SizePixelstoChange:$SizePixelstoChange ActiontoPerform:$ActiontoPerform"

    if (($ResizePixels) -and ($SizePixelstoChange -eq 0)){
        # Write-debug 'No change based on Pixels' 
        return $false
    }

    if ($ActiontoPerform -eq 'MBR_ResizeFromLeft' -or $ActiontoPerform -eq 'Amiga_ResizeFromLeft'){
        if ($Partition.CanResizeLeft -eq $false){
            # Write-debug "Cannot Resize left"
            return $false
        }
    }
    elseif ($ActiontoPerform -eq 'MBR_ResizeFromRight' -or $ActiontoPerform -eq 'Amiga_ResizeFromRight'){
        if ($Partition.CanResizeRight -eq $false){
            # Write-debug "Cannot Resize Right"
            return $false
        }
    }

    if ($PartitionType -eq 'MBR'){
        $BytestoPixelFactor = $WPF_DP_Disk_GPTMBR.BytestoPixelFactor
    }
    elseif ($PartitionType -eq 'Amiga'){
        $AmigaDiskName = $Partition.PartitionName.Substring(0,($Partition.PartitionName.IndexOf('_AmigaDisk_Partition_')+10))
        $BytestoPixelFactor = (Get-Variable -name $AmigaDiskName).Value.BytestoPixelFactor 
    }

    $PartitionToCheck = Get-AllGUIPartitionBoundaries -GPTMBR -Amiga | Where-Object {$_.PartitionName -eq $Partition.PartitionName}

    if (($ResizeBytes) -and ($SizeBytes -eq $PartitionToCheck.PartitionSizeBytes)){
        # Write-debug 'No change based on bytes' 
        return $false
    }

    $MinimumSizeBytes = $null       
    if ($PartitionType -eq 'MBR'){
        if ($Partition.PartitionSubType -eq 'FAT32'){
            $MinimumSizeBytes = $SDCardMinimumsandMaximums.MBRMinimum
        }
        elseif ($Partition.PartitionSubType -eq 'ID76'){
            $AmigaPartitionstoCheck = @(Get-AllGUIPartitionBoundaries -GPTMBR -Amiga | Where-Object {$_.PartitionName -match $Partition.PartitionName -and $_.PartitionType -eq 'Amiga'})
            $AmigatoGPTMBROverhead = (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).value.DiskSizeAmigatoGPTMBROverhead
            $TotalSpaceofAmigaPartitions = $AmigatoGPTMBROverhead
            for ($i = 0; $i -lt $AmigaPartitionstoCheck.Count; $i++) {
                $TotalSpaceofAmigaPartitions += $AmigaPartitionstoCheck[$i].PartitionSizeBytes
            }
            if ($TotalSpaceofAmigaPartitions -gt $SDCardMinimumsandMaximums.ID76Minimum){
                $MinimumSizeBytes = $TotalSpaceofAmigaPartitions 

            }
            else{
                $MinimumSizeBytes = $SDCardMinimumsandMaximums.ID76Minimum
            }
           # Write-Debug "Minimum size of MBR partition (bytes) is: $MinimumSizeBytes"
        }
    }
    elseif ($PartitionType -eq 'Amiga'){
        if ($SDCardMinimumsandMaximums.PFS3Minimum -gt $Partition.ImportedFilesSpaceBytes){
            $MinimumSizeBytes = $SDCardMinimumsandMaximums.PFS3Minimum
        }
        else {
            $MinimumSizeBytes = $Partition.ImportedFilesSpaceBytes
        }
    }

    # Write-debug "Minimum Size bytes is $MinimumSizeBytes"

    if ($SizeBytes){                
       # Write-debug 'Resizing based on bytes'
       
       if ($PartitionType -eq 'MBR'){
           $SizeBytes = Get-MBRNearestSizeBytes -RoundDown -SizeBytes $SizeBytes 
       }
       elseif ($PartitionType -eq 'Amiga'){
        $SizeBytes = Get-AmigaNearestSizeBytes -RoundDown -SizeBytes $SizeBytes
       }

        if ($SizeBytes -lt $MinimumSizeBytes){
            return $false
        }       
        if (($ActiontoPerform -eq 'MBR_ResizeFromRight') -or ($ActiontoPerform -eq 'Amiga_ResizeFromRight')) {
            $BytestoChange = $SizeBytes - $PartitionToCheck.PartitionSizeBytes
            if ($BytestoChange -gt $PartitionToCheck.BytesAvailableRight){
                return $false
            }
        }
        elseif (($ActiontoPerform -eq 'MBR_ResizeFromLeft') -or ($ActiontoPerform -eq 'Amiga_ResizeFromLeft')){
            $BytestoChange = $PartitionToCheck.PartitionSizeBytes - $SizeBytes 
            if ($BytestoChange -gt $PartitionToCheck.BytesAvailableLeft){
                return $false
            }
        }
        
        $NewSizePixels = $SizeBytes/$BytestoPixelFactor
    }

    elseif ($SizePixelstoChange){
        # Write-debug "Resizing based on Pixels"

        if (($ActiontoPerform -eq 'MBR_ResizeFromRight') -or ($ActiontoPerform -eq 'Amiga_ResizeFromRight')) {

        }
        elseif (($ActiontoPerform -eq 'MBR_ResizeFromLeft') -or ($ActiontoPerform -eq 'Amiga_ResizeFromLeft')){
            $SizePixelstoChange = $SizePixelstoChange * -1
        }
        
        if ($PartitionType -eq 'MBR'){
            $BytestoChange = Get-MBRNearestSizeBytes -SizeBytes ($SizePixelstoChange * $BytestoPixelFactor) -RoundDown
        }
        elseif ($PartitionType -eq 'Amiga'){
            $BytestoChange = Get-AmigaNearestSizeBytes -SizeBytes ($SizePixelstoChange * $BytestoPixelFactor) -RoundDown
        }
                        
        if (($ActiontoPerform -eq 'MBR_ResizeFromRight') -or ($ActiontoPerform -eq 'Amiga_ResizeFromRight')) {
            if ($BytestoChange -gt $PartitionToCheck.BytesAvailableRight){
                $BytestoChange = $PartitionToCheck.BytesAvailableRight
            }
        }
        elseif (($ActiontoPerform -eq 'MBR_ResizeFromLeft') -or ($ActiontoPerform -eq 'Amiga_ResizeFromLeft')){
            if ($BytestoChange -gt $PartitionToCheck.BytesAvailableLeft){
                $BytestoChange = $PartitionToCheck.BytesAvailableLeft
                
            }
        }
        if (($PartitionToCheck.PartitionSizeBytes + $BytestoChange) -lt $MinimumSizeBytes){
            $BytestoChange = $MinimumSizeBytes - $PartitionToCheck.PartitionSizeBytes
        }
        
        $SizePixelstoChange = $BytestoChange / $BytestoPixelFactor
        # Write-debug "Action is $ActiontoPerform. Resizing based on Pixels: $SizePixelstoChange. Bytes to change is: $BytestoChange"
        
        $SizeBytes = $PartitionToCheck.PartitionSizeBytes + $BytestoChange

        if  ($PartitionType -eq 'Amiga' -and $SizeBytes -gt $SDCardMinimumsandMaximums.PFS3Maximum){
            $SizeBytes =  $SDCardMinimumsandMaximums.PFS3Maximum
        }

        $NewSizePixels = $SizeBytes/$BytestoPixelFactor     

        if ($NewSizePixels -gt 4){
            $NewSizePixels -= 4
        }
        else {
            $NewSizePixels = 0
        }

    }
    
    # Write-debug "New Size of Partition is $SizeBytes"

    $Partition.PartitionSizeBytes = $SizeBytes
    
   # $WPF_DP_Partition_MBR_2.PartitionSizeBytes
   # $WPF_DP_Partition_MBR_2_AmigaDisk.DiskSizeBytes

   #$PartitionName = 'WPF_DP_Partition_MBR_2'

    if ($Partition.PartitionSubType -eq 'ID76'){      
        Remove-AmigaDiskFreeSpaceBetweenPartitions 
        # Write-debug "Old Size was: $((Get-Variable -name ($PartitionName+'_AmigaDisk')).Value.DiskSizeBytes)"     
        (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.DiskSizeBytes = Get-AmigaDiskSize -AmigaDisk (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).value
        # Write-debug "New size is: $((Get-Variable -name ($PartitionName+'_AmigaDisk')).Value.DiskSizeBytes)"    
        (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.BytestoPixelFactor = (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.DiskSizeBytes / (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.DiskSizePixels
        $AmigaPartitionstoChange = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $Partition.PartitionName } | Sort-Object {[int64]$_.Partition.StartingPositionBytes} 
              
        $Counter = 1
        $LastPartitionEndPixels = 0
        foreach ($AmigaPartition in $AmigaPartitionstoChange) {
            if ($Counter -eq 1){
                $AmounttoSetLeft = $AmigaPartition.Partition.StartingPositionBytes / (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.BytestoPixelFactor
            }
            else {
                $AmounttoSetLeft = $LastPartitionEndPixels
            }
            $AmigaPartition.Partition.Margin = [System.Windows.Thickness]"$AmounttoSetLeft,0,0,0"                
            $AmigaSizePixels = $AmigaPartition.Partition.PartitionSizeBytes  / (Get-Variable -name ($Partition.PartitionName+'_AmigaDisk')).Value.BytestoPixelFactor
            if ($AmigaSizePixels -gt 4){
                $AmigaSizePixels -= 4
            }

            $AmigaPartition.Partition.ColumnDefinitions[1].Width = $AmigaSizePixels

            $LastPartitionEndPixels += ($AmigaSizePixels + 4)
           # Write-debug "Last Partition EndPixels for partition $($AmigaPartition.Name) is: $LastPartitionEndPixels "
            $Counter ++
        }
       
    }

    if (($ActiontoPerform -eq 'MBR_ResizeFromLeft') -or ($ActiontoPerform -eq 'Amiga_ResizeFromLeft')){
        # Write-debug "Resizing from Left. Old Starting Position Bytes is $($PartitionToCheck.StartingPositionBytes). Bytes to change is $BytestoChange. Old Left Margin is: $($PartitionToCheck.LeftMargin). Pixels to change is $($SizePixelstoChange)"
        $Partition.StartingPositionBytes -= $BytestoChange  
       # Write-debug "New Starting Position bytes is: $($Partition.StartingPositionBytes)"
        $AmounttoSetLeft = $PartitionToCheck.LeftMargin  - $SizePixelstoChange
        $Partition.Margin = [System.Windows.Thickness]"$AmounttoSetLeft,0,0,0"
    }
    
    $Partition.ColumnDefinitions[1].Width = $NewSizePixels 
    
    if ($PartitionType -eq 'Amiga'){
        if ($WPF_DP_Amiga_GroupBox.Visibility -eq 'Visible'){      
            $WPF_DP_DiskGrid_Amiga.UpdateLayout()
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }

    }
    elseif ($PartitionType -eq 'MBR'){
        $WPF_DP_DiskGrid_GPTMBR.UpdateLayout()
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)

    }        
        
    return $true
    
}
