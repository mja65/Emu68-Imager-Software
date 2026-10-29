function Get-GPTMBRPartitionDefaultDetails {
    param (
        $DiskSizeBytes,
        $DiskType,
        $PartitionType
    )
   
    # $DiskType = "GPT"
    # $PartitionType = "Data"

    $PartitionTypeDetails = (Get-InputFileCSV -CSV 'PartitionTypes').where({ $_.DefaultPartition -eq $true -and $_.DiskType -eq $DiskType -and $_.PartitionType -eq $PartitionType}) 

    $DatatoReturn = [PSCustomObject]@{
       PartitionSizeBytes = $null
       MinimumSizeBytes = $PartitionTypeDetails.MinimumSizeBytes
       PartitionName = $PartitionTypeDetails.PartitionName 
    }

    If ($PartitionType -eq "Emu68Boot"){
        If ($DiskType -eq "GPT" -and ($DiskSizeBytes)){
            $DatatoReturn.PartitionSizeBytes =  $PartitionTypeDetails.DefaultMaximumAddSizeBytes
        }
        elseif ($DiskType -eq "MBR" -and ($DiskSizeBytes)){
            if ($DiskSizeBytes/$PartitionTypeDetails.SizeDivider -ge $PartitionTypeDetails.DefaultMaximumAddSizeBytes){
                $DatatoReturn.PartitionSizeBytes = $PartitionTypeDetails.DefaultMaximumAddSizeBytes 
            } 
            else{   
                $DatatoReturn.PartitionSizeBytes = ($DiskSizeBytes/$PartitionTypeDetails.SizeDivider) 
            }
        }

    }
    if ($PartitionType -eq "Data" -and ($DiskSizeBytes)){
        if ($DiskSizeBytes/$PartitionTypeDetails.SizeDivider -ge $PartitionTypeDetails.DefaultMaximumAddSizeBytes){
            $DatatoReturn.PartitionSizeBytes = $PartitionTypeDetails.DefaultMaximumAddSizeBytes 
        } 
        else{   
            $DatatoReturn.PartitionSizeBytes = ($DiskSizeBytes/$PartitionTypeDetails.SizeDivider) 

        }
    }
    return $DatatoReturn
    
}          