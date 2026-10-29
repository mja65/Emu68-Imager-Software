function Get-MBRDiskFreeSpace {
    param (
        $Disk,
        $Position,
        $PartitionNameNextto
    )
    
    # $Disk = $WPF_DP_Disk_GPTMBR
    # $Disk = $WPF_DP_Partition_ID76_2_AmigaDisk
    # $PartitionNameNextto = 'WPF_DP_Partition_MBR_2'
    # $Position = 'AtEnd'

    #$PartitionstoCheck = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    $PartitionstoCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | Where-Object {$_.PartitionType -eq $Disk.DiskType} 
          
    if ($Position -eq 'AtEnd'){
        if ($PartitionstoCheck){
            return $PartitionstoCheck[$PartitionstoCheck.Count-1].BytesAvailableRight
        }
        else{
            return $Disk.DiskSizeBytes - $Disk.GPTMBROverheadBytes
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