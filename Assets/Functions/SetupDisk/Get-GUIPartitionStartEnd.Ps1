function Get-GUIPartitionStartEnd {
    param (
        $PartitionType,
        $AmigaDiskName 

    )

    # $AmigaDiskName = 'WPF_DP_Partition_MBR_2_AmigaDisk'
    # $PartitionType = 'MBR'
    # $PartitionType = 'Amiga'

    $ValuetoReturn = [PSCustomObject]@{
        StartingPositionPixels = 0
        EndingPositionPixels = 0
        StartingPositionBytes = 0
        EndingPositionBytes = 0
    }

    if ($PartitionType -eq 'MBR'){
        $ListofPartitions  = @(Get-AllGUIPartitions -PartitionType $PartitionType | Sort-Object {[int64]$_.value.StartingPositionBytes})
    }
    elseif ($PartitionType -eq 'Amiga'){
        $ID76Partition = $AmigaDiskName.Substring(0,$AmigaDiskName.IndexOf('_AmigaDisk'))        
        $ListofPartitions  = @(Get-AllGUIPartitions -PartitionType $PartitionType | Where-Object {$_.Name -Match $ID76Partition } | Sort-Object {[int64]$_.value.StartingPositionBytes})
    }
     
    if (-not $ListofPartitions){ # No Partitions at all
        return $ValuetoReturn 
    }

    $TotalPartitions = $ListofPartitions.Count
    
    $ValuetoReturn.StartingPositionPixels = $ListofPartitions[0].Value.Margin.Left
    $ValuetoReturn.StartingPositionBytes = $ListofPartitions[0].Value.StartingPositionBytes
    $ValuetoReturn.EndingPositionPixels = $ListofPartitions[$TotalPartitions-1].Value.Margin.Left + (Get-GUIPartitionWidth -Partition $ListofPartitions[$TotalPartitions-1].Value)
    $ValuetoReturn.EndingPositionBytes = $ListofPartitions[$TotalPartitions-1].Value.StartingPositionBytes + $ListofPartitions[$TotalPartitions-1].Value.PartitionSizeBytes
 
    return $ValuetoReturn                  
}
