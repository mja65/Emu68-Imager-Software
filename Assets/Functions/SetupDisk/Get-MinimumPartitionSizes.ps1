function Get-MinimumPartitionSizes {
    param (
        $DiskSizeBytes,
        $DiskType
    )

    # $DiskType = "MBR"
    # $DiskSizeBytess = 2147483648

    $DiskTypeDetails = (Get-InputFileCSV -CSV 'DiskTypes').where({ $_.DiskType -eq $DiskType }) 
    $PartitionTypeDetails = (Get-InputFileCSV -CSV 'PartitionTypes').where({ $_.DiskType -eq $DiskType }) 
    $AmigaPartitionDefaults = (Get-InputFileCSV -CSV 'DiskDefaults')

    $DiskMinimumSizesBytes = [PSCustomObject]@{
        MaximumNumberPartitions = $DiskTypeDetails.MaximumNumberPartitions
        MaximumNumberRDBPartitions = $AmigaPartitionDefaults.where({ $_.Disk -eq "Work" }).MaximumNumberPartitions
        EMU68BOOTMinimum = $DiskTypeDetails.EMU68PartitionMinimumSizeBytes
        GPTDataMinimum = $DiskTypeDetails.GPTDataMinimumSizeBytes
        MBRMinimum = $DiskTypeDetails.DataPartitionMinimumSizeBytes
        GPTMinimum = $null
        ID76Minimum = $DiskTypeDetails.AmigaPartitionMinimumSizeBytes
        PFS3Maximum = $AmigaPartitionDefaults.where({ $_.Disk -eq "Work" }).MaximumSizeBytes
        SystemMinimum = $AmigaPartitionDefaults.where({ $_.Disk -eq "System" }).MinimumSizeBytes
        PFS3Minimum = $AmigaPartitionDefaults.where({ $_.Disk -eq "Work" }).MinimumSizeBytes
        EMU68BOOTDefault = if ($DiskSizeBytes/$DiskTypeDetails.Emu68PartitionSizeBootDivider -ge $DiskTypeDetails.Emu68PartitionDefaultMaximumAddSizeBytes){ 
            $DiskTypeDetails.Emu68PartitionDefaultMaximumAddSizeBytes 
            } 
            else {  
                $DiskSizeBytes/$DiskTypeDetails.Emu68PartitionSizeBootDivider 
            }
        WorkbenchDefault = if ($DiskSizeBytes/$DiskTypeDetails.AmigaPartitionSizeBootDivider  -ge $DiskTypeDetails.AmigaPartitionDefaultMaximumAddSizeBytes){
            $DiskTypeDetails.AmigaPartitionDefaultMaximumAddSizeBytes
        }
        else {
            $DiskSizeBytes/$DiskTypeDetails.AmigaPartitionSizeBootDivider
            
        }
        DefaultAddMBRSize = $DiskTypeDetails.DataPartitionDefaultAddSizeBytes
        DefaultAddGPTSize = $null 
        DefaultAddID76Size = $DiskTypeDetails.AmigaPartitionDefaultAddSizeBytes
        DefaultAddPFS3Size = $AmigaPartitionDefaults.where({ $_.Disk -eq "Work" }).DefaultAddSizeBytes  
    }

    return $DiskMinimumSizesBytes

}
