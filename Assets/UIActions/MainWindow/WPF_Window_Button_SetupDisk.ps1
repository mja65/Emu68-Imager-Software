$WPF_Window_Button_SetupDisk.Add_Click({
   
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }

    Confirm-ValidPackageInstallDrives 
    
    # Write-debug "Set up Disk button pressed"


    $Script:GUICurrentStatus.CurrentWindow = 'DiskPartition'

        for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_PackageSelection.Name){
                $WPF_Window_Main.Children.Remove($WPF_PackageSelection)
            }
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_StartPage.Name){
                $WPF_Window_Main.Children.Remove($WPF_StartPage)
            }
        }
       
        for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_Partition.Name){
                $IsChild = $true
            }
        }
    
        if ($IsChild -ne $true){
            $WPF_Window_Main.AddChild($WPF_Partition)
        }
        
        foreach ($Visual in $Script:GUIPartitionVisuals) {
            $DefaultColourVisual = Get-VisualBrushDefaultPartition -Colour $Visual.DefaultColour
            $ColourVisual = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Visual.Colour)
            if ($Visual.PartitionType -eq "MBR"){
                if ($Visual.PartitionSubType -eq "FAT32"){
                    $WPF_DP_MBRSimple_Legend_FAT32Default.Fill = $DefaultColourVisual
                    $WPF_DP_MBR_Legend_FAT32Default.Fill = $DefaultColourVisual 
                    $WPF_DP_MBR_Legend_FAT32.Fill = $ColourVisual
                }
                elseif ($Visual.PartitionSubType -eq "ID76"){
                    $WPF_DP_MBRSimple_Legend_ID76Default.Fill = $DefaultColourVisual
                    $WPF_DP_MBR_Legend_ID76Default.Fill = $DefaultColourVisual
                    $WPF_DP_MBR_Legend_ID76.Fill = $ColourVisual
                }
            }
            elseif ($Visual.PartitionType -eq "GPT"){
                if ($Visual.PartitionSubType -eq "System"){
                    $WPF_DP_GPT_Legend_System.Fill = $DefaultColourVisual
                }
                elseif ($Visual.PartitionSubType -eq "Data"){
                    $WPF_DP_GPT_Legend_Data.Fill = $ColourVisual
                    $WPF_DP_GPT_Legend_DataDefault.Fill = $DefaultColourVisual
                }
                elseif ($Visual.PartitionSubType -eq "Amiga"){
                    $WPF_DP_GPT_Legend_Amiga.Fill = $ColourVisual
                    $WPF_DP_GPT_Legend_AmigaDefault.Fill = $DefaultColourVisual
                }
        
            }
            elseif ($Visual.PartitionType -eq "Amiga"){
                if ($Visual.PartitionSubType -eq "Workbench"){
                    $WPF_DP_RDBSimple_Legend_Workbench.Fill = $DefaultColourVisual
                    $WPF_DP_RDB_Legend_Workbench.Fill = $DefaultColourVisual
                }        
                if ($Visual.PartitionSubType -eq "Work"){
                    $WPF_DP_RDBSimple_Legend_Work.Fill = $ColourVisual
                    $WPF_DP_RDB_Legend_Work.Fill = $ColourVisual
                } 
            }
        }

        $WPF_DP_DiskGrid_GPTMBR.UpdateLayout()
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga) 
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)        

        update-ui -MainWindowButtons -HighlightSelectedPartitions -DiskPartitionWindow -FreeSpaceAlert  

})
 