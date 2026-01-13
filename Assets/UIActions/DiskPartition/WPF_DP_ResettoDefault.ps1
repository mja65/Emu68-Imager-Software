$WPF_DP_ResettoDefault.Add_Click({
       
       $Msg_Header = "About to reset Disks"
       $Msg_Body = "You are about to reset the disk set up. Please confirm you wish to do this."
       
        if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'OK'){
            
            # if ($Script:GUIActions.InstallOSFiles -eq $true){

            # }
            # else {
                
            # }

            $Script:GUICurrentStatus.SelectedAmigaPartition = $null
            $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
            $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
            $Script:GUIActions.OutputPath = $null
            $Script:GUIActions.ImageSizeSelected = $null
            $Script:GUIActions.OutputType = $null
            if ($Script:GUIActions.InstallOSFiles -eq $false){
                $Script:GUIActions.UnicamEnabled = $false    
                $Script:GUIActions.UnicamStartonBoot = [bool]$null
                $Script:GUIActions.UnicamScalingType = $null
                #$Script:GUIActions.UnicamPhase = $null
                $Script:GUIActions.UnicamBParameter = $null
                $Script:GUIActions.UnicamCParameter = $null
                $Script:GUIActions.UnicamSizeXPosition = $null
                $Script:GUIActions.UnicamSizeYPosition = $null
                $Script:GUIActions.UnicamOffsetXPosition = $null
                $Script:GUIActions.UnicamOffsetYPosition = $null
                $Script:GUIActions.WorkbenchBackDropEnabled = $false
                $Script:GUIActions.ScreenModeType = "Native"
                $Script:GUIActions.AvailableScreenModesWB = Get-InputCSVs -ScreenModesWB
                $Script:GUIActions.AvailableScreenModesWB | Where-Object 'Type' -eq "RTG" | ForEach-Object {
                    $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                    if ($_.DefaultMode -eq $true){
                        $Script:GUIActions.ScreenModetoUseWB = $_.FriendlyName
                        $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $_.FriendlyName
                        $WPF_StartPage_WorkbenchColour_Slider.Value = $_.DefaultDepth
                        $Script:GUIActions.ScreenModeWBColourDepth = $WPF_StartPage_WorkbenchColour_Slider.Value 
                        $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)      
                    }
                }            
            } 
            $Script:GUIActions.InstallOSFiles = $true
            $Script:GUIActions.DiskSizeSelected = $null
        
            $Script:WPF_DP_MediaSelect_Type_DropDown.SelectedItem = $null
            $WPF_DP_MediaSelect_DropDown.SelectedItem = $null
            Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
        
            if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
                Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
            }
        
            Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions -MainWindowButtons -Emu68Settings
        
        }
        else {
            return
        }
    
})