function Get-AmigaDiskFreeSpace {
    param (
        $Disk,
        $Position,
        $PartitionNameNextto
    )
    
    # $Disk = $WPF_DP_Disk_GPTMBR
    # $Disk = $WPF_DP_Partition_MBR_2_AmigaDisk
    # $PartitionNameNextto = 'WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1'
    # $Position = 'Right'

    #$PartitionstoCheck = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    if ($Disk.DiskType -eq 'MBR' -or $Disk.DiskType -eq 'GPT'){
        $PartitionstoCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | Where-Object {$_.PartitionType -eq $Disk.DiskType} 
    }
    elseif ($Disk.DiskType -eq 'Amiga'){
        $ID76Partition = $AmigaDiskName.Substring(0,$AmigaDiskName.IndexOf('_AmigaDisk'))  
        $PartitionstoCheck = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionType -eq $Disk.DiskType -and $_.PartitionName -match $ID76Partition} 
    }
           
    if ($Position -eq 'AtEnd'){
        if ($PartitionstoCheck){
            return $PartitionstoCheck[$PartitionstoCheck.Count-1].BytesAvailableRight
        }
        else{
            if ($Disk.DiskType -eq 'MBR' -or $Disk.DiskType -eq 'GPT'){
                return $Disk.DiskSizeBytes - 2097152
            }
            elseif ($Disk.DiskType -eq 'Amiga'){
                
            }
        }
    }
    else{
        $PartitiontoCheck = $PartitionstoCheck | Where-Object {$_.PartitionName -eq $PartitionNameNextto}
        if ($Position -eq 'Right'){
            return $PartitiontoCheck.BytesAvailableRight 
        }
        elseif ($Position -eq 'Left'){
            return $PartitiontoCheck.BytesAvailableLeft 
        }
    }



}


