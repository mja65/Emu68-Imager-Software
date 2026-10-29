function Get-NextGUIPartition {
    param (
        $PartitiontoCheck,
        $PartitionType,
        $Side
    )
    
    # $PartitionType = 'MBR'
    # $Side = "Right"
    # $PartitiontoCheck = $Script:GUICurrentStatus.SelectedGPTMBRPartition

    if ($PartitionType -eq 'Amiga'){
        if ($PartitiontoCheck){
            $AmigaDiskName = ($PartitiontoCheck.PartitionName.Substring(0,($PartitiontoCheck.PartitionName.IndexOf('_AmigaDisk_Partition_')+10)))    
        }
        else{
            $AmigaDiskName = "$($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName)_AmigaDisk"
        }
        $ExistingPartitionstoCheck = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $AmigaDiskName }
    }
    elseif ($PartitionType -eq 'MBR' -or $PartitionType -eq 'GPT'){
        $ExistingPartitionstoCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries
    }
    
    if ($PartitiontoCheck){
        for ($i = 0; $i -lt $ExistingPartitionstoCheck.Count; $i++) {
            if ($PartitiontoCheck.PartitionName -eq $ExistingPartitionstoCheck[$i].PartitionName){
                if ($Side -eq "Left"){
                    if ($i -eq 0){
                        $NextPartition = $ExistingPartitionstoCheck[$ExistingPartitionstoCheck.Count-1].Partition
                    }
                    else{
                        $NextPartition = $ExistingPartitionstoCheck[$i-1].Partition
                    }
                }
                elseif ($Side -eq "Right"){
                    if ($i -eq $ExistingPartitionstoCheck.Count-1){
                        $NextPartition = $ExistingPartitionstoCheck[0].Partition
                    }
                    else{
                        $NextPartition = $ExistingPartitionstoCheck[$i+1].Partition
                    }
                }
                return $NextPartition
            }
        }
    }
    else{
        if ($Side -eq 'Right'){
            $NextPartition = $ExistingPartitionstoCheck[0].Partition
        }
        elseif ($Side -eq 'Left'){
            $NextPartition = $ExistingPartitionstoCheck[$ExistingPartitionstoCheck.Count-1].Partition
        }
    }

    return $NextPartition

}