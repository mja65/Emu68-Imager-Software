function Set-InitialDiskValues {
    param (
       $DiskType,
       $SizeBytes,
       [Switch]$LoadSettings
    )

    # $DiskType = "GPT"
    # $DiskType = "MBR"
    # $SizeBytes = 124733221376

    $Script:GUIActions.DiskSizeSelected = $true
    #$WPF_DP_Amiga_GroupBox.Visibility = 'Visible'
    $WPF_DP_GPTMBR_GroupBox.Visibility = 'Visible'
    Write-Host "SizeBytes is: $SizeBytes"
    Add-InitialGPTMBRDisk -DiskSizeBytes $SizeBytes -DiskType $Script:GUIActions.DiskType

                                                           
    if (-not ($LoadSettings)){
        if ($DiskType -eq 'MBR'){
            $Emu68BootDetails = Get-GPTMBRPartitionDefaultDetails -DiskType "MBR" -DiskSizeBytes $SizeBytes -PartitionType "Emu68Boot"
            $SizeBytesFAT32 = Get-MBRNearestSizeBytes -RoundDown -SizeBytes $Emu68BootDetails.PartitionSizeBytes
            $RemainingSpace = Get-MBRNearestSizeBytes -RoundDown -SizeBytes ($WPF_DP_Disk_GPTMBR.DiskSizeBytes - $WPF_DP_Disk_GPTMBR.GPTMBROverheadBytes - $SizeBytesFAT32) 
            #Write-host "SizeBytesFAT32 is: $SizeBytesFAT32 RemainingSpace is: $RemainingSpace"
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'MBR' -PartitionSubType 'FAT32' -AddType 'Initial' -DefaultPartition -SizeBytes $SizeBytesFAT32 -VolumeName $Emu68BootDetails.PartitionName 
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'MBR' -PartitionSubType 'ID76' -AddType 'Initial' -DefaultPartition -SizeBytes $RemainingSpace    
        }
        elseif ($DiskType -eq 'GPT'){
            $SystemDetails = Get-GPTMBRPartitionDefaultDetails -DiskType "GPT" -DiskSizeBytes $SizeBytes -PartitionType "Emu68Boot"
            $DataDetails = Get-GPTMBRPartitionDefaultDetails -DiskType "GPT" -DiskSizeBytes $SizeBytes -PartitionType "Data"
            $SizeBytesSystem = Get-MBRNearestSizeBytes -RoundDown -SizeBytes $SystemDetails.PartitionSizeBytes
            $SizeBytesData = Get-MBRNearestSizeBytes -RoundDown -SizeBytes $DataDetails.PartitionSizeBytes
            $RemainingSpace = Get-MBRNearestSizeBytes -RoundDown -SizeBytes ($WPF_DP_Disk_GPTMBR.DiskSizeBytes - $WPF_DP_Disk_GPTMBR.GPTMBROverheadBytes - $SizeBytesSystem - $SizeBytesData)
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'GPT' -PartitionSubType 'System' -AddType 'Initial' -DefaultPartition -SizeBytes $SizeBytesSystem -VolumeName $SystemDetails.PartitionName
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'GPT' -PartitionSubType 'Data' -AddType 'Initial' -DefaultPartition -SizeBytes $SizeBytesData -VolumeName $DataDetails.PartitionName
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'GPT' -PartitionSubType 'Amiga' -AddType 'Initial' -DefaultPartition -SizeBytes (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $RemainingSpace)           
        }
    }
}
