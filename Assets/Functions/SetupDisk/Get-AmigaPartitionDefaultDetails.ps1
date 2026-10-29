function Get-AmigaPartitionDefaultDetails {
    param (
        $AmigaPartition,
        $DiskSizeBytes
    )

    # $AmigaPartition = "System"
    $PartitionTypeDetails = (Get-InputFileCSV -Csv 'DiskDefaults').where({ $_.Type -eq "Amiga" -and $_.Disk -eq $AmigaPartition})
    
    $DatatoReturn = [PSCustomObject]@{
       PartitionSizeBytes = $null
       MaximumSizeBytes = $PartitionTypeDetails.MaximumSizeBytes
       MinimumSizeBytes = $PartitionTypeDetails.MinimumSizeBytes
       MaximumNumberPartitions = $PartitionTypeDetails.MaximumNumberPartitions
       DeviceName = $PartitionTypeDetails.DeviceName
       VolumeName = $PartitionTypeDetails.VolumeName
       Buffers = $PartitionTypeDetails.Buffers
       MaxTransfer = $PartitionTypeDetails.MaxTransfer
       DosType = $PartitionTypeDetails.DosType
       Priority = [int]$PartitionTypeDetails.Priority 
       BootableFlag = $PartitionTypeDetails.BootableFlag
       Mask = $PartitionTypeDetails.Mask
    }

    If ($AmigaPartition -eq "System"){
        $DatatoReturn.PartitionSizeBytes = if ($DiskSizeBytes/$PartitionTypeDetails.SizeDivider -ge $PartitionTypeDetails.DefaultMaximumAddSizeBytes){
            $PartitionTypeDetails.DefaultMaximumAddSizeBytes
        }
        else {
            $DiskSizeBytes/$PartitionTypeDetails.SizeDivider
        }
    }
    
    return $DatatoReturn 

}
 