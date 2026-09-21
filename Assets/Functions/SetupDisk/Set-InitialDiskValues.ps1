function Set-InitialDiskValues {
    param (
       $DiskType,
       $SizeBytes,
       [Switch]$LoadSettings
    )

    $Emu68BootVolumeNametouse = ((Get-InputFileCSV -CSV 'DiskDefaults') | Where-Object {$_.Type -eq "Non-Amiga"} | Select-Object 'VolumeName').VolumeName

    $Script:GUIActions.DiskSizeSelected = $true
    $Script:GUIActions.DiskTypeSelected = $DiskType
    #$WPF_DP_Amiga_GroupBox.Visibility = 'Visible'
    $WPF_DP_GPTMBR_GroupBox.Visibility = 'Visible'

    if ($DiskType -eq 'PiStorm - MBR'){
        $DiskTypetouse = 'MBR'
        Add-InitialGPTMBRDisk -DiskSizeBytes $SizeBytes -DiskType $Script:GUIActions.DiskTypeSelected 
        $Script:SDCardMinimumsandMaximums = Get-MinimumPartitionSizes  -DiskType $Script:GUIActions.DiskTypeSelected `
                            -SizeofDiskBytes $WPF_DP_Disk_GPTMBR.DiskSizeBytes `
                            -EMU68BOOTDivider 15 `
                            -EMU68BOOTMinimum (35840*1024) `
                            -MBRMinimum (35840*1024) `
                            -GPTMinimum $null `
                            -ID76Minimum (35840*1024) `
                            -PFS3Minimum (10*1024*1024) `
                            -PFS3Maximum (101*1024*1024*1024) `
                            -SystemMinimum (100*1024*1024) `
                            -EMU68BOOTDefaultMaximum (1024*1024*1024) `
                            -WorkbenchDefaultMaximum (1024*1024*1024) `
                            -WorkbenchDivider 15 `
                            -DefaultAddMBRSize 1073741824 `
                            -DefaultAddGPTSize $null `
                            -DefaultAddID76Size 1073741824 `
                            -DefaultAddPFS3Size 536870912
 
    }
    elseif ($DiskType -eq 'PiStorm - GPT'){
        $DiskTypetouse = 'GPT'
        Write-ErrorMessage -Message "Error in coding - PiStorm - GPT!"
        $WPF_MainWindow.Close()
        exit
    }
    elseif ($DiskType -eq 'Amiga - RDB'){
        Write-ErrorMessage -Message "Error in coding - Amiga - RDB!"
        $WPF_MainWindow.Close()
        exit
    }
                                                               
    if (-not ($LoadSettings)){
        if ($DiskType -eq 'PiStorm - MBR'){
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'MBR' -PartitionSubType 'FAT32' -AddType 'Initial' -DefaultPartition -SizeBytes (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $Script:SDCardMinimumsandMaximums.EMU68BOOTDefault) -VolumeName  $Emu68BootVolumeNametouse 
            $RemainingSpace = ($WPF_DP_Disk_GPTMBR.DiskSizeBytes - $WPF_DP_Disk_GPTMBR.MBROverheadBytes - (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $Script:SDCardMinimumsandMaximums.EMU68BOOTDefault))
            Add-GUIPartitiontoGPTMBRDisk -PartitionType 'MBR' -PartitionSubType 'ID76' -AddType 'Initial' -DefaultPartition -SizeBytes (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $RemainingSpace)    
        }
    }
}
