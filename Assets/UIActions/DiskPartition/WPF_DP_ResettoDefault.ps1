$WPF_DP_ResettoDefault.Add_Click({
       
       $Msg_Header = "About to reset Disks"
       $Msg_Body = "You are about to reset the disk set up. Please confirm you wish to do this."
       
        if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'OK'){
            
            $Script:GUICurrentStatus.SelectedAmigaPartition = $null
            $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
            $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
            $Script:GUIActions.OutputPath = $null
            $Script:GUIActions.ImageSizeSelected = $null
            $Script:GUIActions.OutputType = $null
            $Script:GUIActions.InstallOSFiles = $true
            $Script:GUIActions.DiskSizeSelected = $null
        
            $Script:WPF_DP_MediaSelect_Type_DropDown.SelectedItem = $null
        
            Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
        
            if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
                Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
            }
        
            Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions
        
        }
        else {
            return
        }
    
})