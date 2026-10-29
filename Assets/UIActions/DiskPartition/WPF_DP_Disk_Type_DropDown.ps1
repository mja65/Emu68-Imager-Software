Get-InputFileCSV -CSV "DiskTypes" | ForEach-Object {
    $WPF_DP_Disk_Type_DropDown.AddChild($_.DiskTypeFriendlyName)
    if ($_.Default -eq $true){
        $Script:GUIActions.DiskType = $_.DiskType
    }
        
}

$WPF_DP_Disk_Type_DropDown.add_selectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }    

    $ChangedDiskTypeDetails = (Get-InputFileCSV -CSV "DiskTypes").where({ $WPF_DP_Disk_Type_DropDown.SelectedItem -eq $_.DiskTypeFriendlyName })
    $CurrentGPTMBRDisk = ($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries).PartitionType | Select-Object -Unique

    If (($CurrentGPTMBRDisk -eq 'MBR' -and $ChangedDiskTypeDetails.DiskType -eq 'GPT') -or ($CurrentGPTMBRDisk -eq 'GPT' -and $ChangedDiskTypeDetails.DiskType -eq 'MBR')) {
        $Msg_Header = "Changing Disk Type"
        $Msg_Body = "You are changing disk types but have already started setting up the disk. This will reset the set up. Please confirm you wish to do this."
        if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'Cancel'){
            $PriorDiskTypeDetails = (Get-InputFileCSV -CSV "DiskTypes").where({ $Script:GUIActions.DiskType -eq $_.DiskType }) 
            $WPF_DP_Disk_Type_DropDown.SelectedItem = $PriorDiskTypeDetails.DiskTypeFriendlyName
            return
        }

    }
    
    $Script:GUIActions.DiskType = $ChangedDiskTypeDetails.DiskType
    
    if ($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries) {
        $SizeBytes = $Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes
        $Script:GUICurrentStatus.SelectedAmigaPartition = $null
        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
        $Script:GUIActions.OutputPath = $null
        $Script:GUIActions.ImageSizeSelected = $null
        $Script:GUIActions.OutputType = $null
        Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
        if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
            Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
        }
        Set-InitialDiskValues -DiskType $Script:GUIActions.DiskType -SizeBytes $SizeBytes
    }
        
    Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions -MainWindowButtons -Emu68Settings
    return
    
})
    





    
    
    
    
    
