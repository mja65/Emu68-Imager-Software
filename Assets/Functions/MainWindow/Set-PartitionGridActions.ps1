function Set-PartitionGridActions {
    param (
    )

    $WPF_Partition.add_MouseLeftButtonUp({
        if ($Script:GUICurrentStatus.CurrentWindow -eq 'DiskPartition'){
            $Script:GUICurrentStatus.ActionToPerform = $null
            $Script:GUICurrentStatus.LastCommandTime = $null
            $Script:GUICurrentStatus.MousePositionXatTimeofPress = $null
            $Script:GUICurrentStatus.MousePositionyatTimeofPress = $null
        }
    })
    
    $WPF_Window_Main.Add_MouseLeave({
        $WPF_Partition.Cursor = ''
        $Script:GUICurrentStatus.PartitionHoveredOver = $null
        $Script:GUICurrentStatus.ActionToPerform = $null
        $Script:GUICurrentStatus.LastCommandTime = $null
        $Script:GUICurrentStatus.MousePositionXatTimeofPress = $null
        $Script:GUICurrentStatus.MousePositionyatTimeofPress = $null
        # Write-debug "Out of bounds"
    })
    
 $WPF_Window_Main.add_MouseMove({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true) {
            return
        }
        $CurrentTime = (Get-Date)
        $ThrottleIntervalMs = 30 # Adjust this value (e.g., 16ms for ~60 FPS, 30ms for ~30 FPS)
        # Only proceed if enough time has passed since the last update
        if (($CurrentTime - $Script:GUICurrentStatus.LastMouseMoveUpdateTime).TotalMilliseconds -lt $ThrottleIntervalMs) {
            return
        }
        
        $Script:GUICurrentStatus.LastMouseMoveUpdateTime = $CurrentTime
               
        if (($Script:GUICurrentStatus.CurrentWindow -eq 'DiskPartition') -and ($WPF_DP_GPTMBR_GroupBox.Visibility -eq 'Visible')){

            # Measure Get-MouseCoordinatesRelativetoWindow
           # $measureResult_GetCoords = Measure-Command {
                $MouseCoordinates = Get-MouseCoordinatesRelativetoWindow
           # }
          #  Write-Host "  Get-MouseCoordinatesRelativetoWindow: $($measureResult_GetCoords.TotalMilliseconds)ms"


            $Script:GUICurrentStatus.CurrentMousePositionX = $MouseCoordinates.MousePositionRelativetoWindowX
            $Script:GUICurrentStatus.CurrentMousePositionY = $MouseCoordinates.MousePositionRelativetoWindowY
            $Script:GUICurrentStatus.MouseStatus = $MouseCoordinates.MouseButtons 
         #   $measureResult_GetHighlight = Measure-Command {
                $Script:GUICurrentStatus.PartitionHoveredOver = (Get-HighlightedGUIPartition -MouseX $Script:GUICurrentStatus.CurrentMousePositionX -MouseY $Script:GUICurrentStatus.CurrentMousePositionY)
          #  }
          #  Write-Host "  Get-HighlightedGUIPartition: $($measureResult_GetHighlight.TotalMilliseconds)ms"
            #Write-Debug "Partition Hovered over is: $($Script:GUICurrentStatus.PartitionHoveredOver)"
            if (-not ($Script:GUICurrentStatus.PartitionHoveredOver)){
                $WPF_Partition.Cursor = ''   
            }
            else {
                if ($Script:GUICurrentStatus.PartitionHoveredOver.PartitionName -eq $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName -or $Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName){
                    if ($Script:GUICurrentStatus.PartitionHoveredOver.ResizeZone){
                        $WPF_Partition.Cursor = "SizeWE"
                    }
                    else {
                        $WPF_Partition.Cursor = "Hand"
                    }
                }
                else {
                    $WPF_Partition.Cursor = ''  
                }

            }
            # Write-debug "X Not Window:$($MouseCoordinates.MousePositionX) X:$($MouseCoordinates.MousePositionRelativetoWindowX) Y Not Window:$($MouseCoordinates.MousePositionY) Y:$($MouseCoordinates.MousePositionRelativetoWindowY) Buttons:$($MouseCoordinates.MouseButtons) MouseOverWindow:$($WPF_Window_Main.IsMouseOver) Hovered Over:$($Script:GUICurrentStatus.PartitionHoveredOver)"
            if ($Script:GUICurrentStatus.ActionToPerform){
                $PerformAction = $false
                $CurrentTime = (Get-Date)
                if ($null -eq $Script:GUICurrentStatus.LastCommandTime){
                    $PerformAction = $true
                }
                else {
                    if ((($CurrentTime - $Script:GUICurrentStatus.LastCommandTime).TotalMilliseconds -ge 20) -and ($Script:GUICurrentStatus.MouseStatus -eq 'Left')){
                        $PerformAction = $true
                    }

                }
                if ($PerformAction -eq $true){
                    $Script:GUICurrentStatus.LastCommandTime = $CurrentTime
                    # Write-debug "Action: $($Script:GUICurrentStatus.ActionToPerform)"   
                    $AmounttoMove = $Script:GUICurrentStatus.CurrentMousePositionX - $Script:GUICurrentStatus.MousePositionXatTimeofPress
                    $Script:GUICurrentStatus.MousePositionXatTimeofPress = $Script:GUICurrentStatus.CurrentMousePositionX 

                   # Measure the partition modification functions
              #      $measureResult_SetPartition = Measure-Command {                    
                        if (($Script:GUICurrentStatus.ActionToPerform -eq 'Amiga_ResizeFromRight') -or ($Script:GUICurrentStatus.ActionToPerform -eq 'Amiga_ResizeFromLeft')) {
                            $WPF_Partition.Cursor = "SizeWE"
                            # Write-debug "Amount to Resize:$AmounttoMove"
                            if ((Set-GUIPartitionNewSize -ResizePixels -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -ActiontoPerform $Script:GUICurrentStatus.ActionToPerform -PartitionType 'Amiga' -SizePixelstoChange $AmounttoMove) -eq $false){
                                
                            }        
                        }
    
                        elseif (($Script:GUICurrentStatus.ActionToPerform -eq 'GPTMBR_ResizeFromRight') -or ($Script:GUICurrentStatus.ActionToPerform -eq 'GPTMBR_ResizeFromLeft')) {
                            $WPF_Partition.Cursor = "SizeWE"
                            # Write-debug "Amount to Resize:$AmounttoMove"
                            if ((Set-GUIPartitionNewSize -ResizePixels -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition -ActiontoPerform $Script:GUICurrentStatus.ActionToPerform -PartitionType $Script:GUIActions.DiskType -SizePixelstoChange $AmounttoMove) -eq $false){
                
                            }
                        }
    
                        elseif ($Script:GUICurrentStatus.ActionToPerform -eq 'GPTMBR_Move'){
                            $WPF_Partition.Cursor = "Hand"
                            # Write-debug "Amount to Move:$AmounttoMove"                  
                            if ((Set-GUIPartitionNewPosition -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition -AmountMovedPixels $AmounttoMove -PartitionType $Script:GUIActions.DiskType) -eq $false){
                                # Write-debug "Cannot Move!"
                            }       
                        }
    
                        elseif ($Script:GUICurrentStatus.ActionToPerform -eq 'Amiga_Move'){
                            $WPF_Partition.Cursor = "Hand"
                            # Write-debug "Amount to Move:$AmounttoMove"
                            if ((Set-GUIPartitionNewPosition -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -AmountMovedPixels $AmounttoMove -PartitionType 'Amiga') -eq $false){
                                # Write-debug "Cannot Move!"
                            }                        
                        }
                #    }

              #      Write-Host "  Set-GUIPartitionNewSize/Position: $($measureResult_SetPartition.TotalMilliseconds)ms"
                    # Measure Update-UI
              #      $measureResult_UpdateUI = Measure-Command {
                        Update-UI -UpdateInputBoxes
                    }
             #       Write-Host "  Update-UI: $($measureResult_UpdateUI.TotalMilliseconds)ms"


          #       }
                elseif ($PerformAction -eq $false){
                    # Write-debug "Action: $($Script:GUICurrentStatus.ActionToPerform) - Too Soon!"
                }  
            } 
        }
    })

    $WPF_Window_Main.add_MouseLeftButtonDown({
            if ($Script:GUICurrentStatus.FileBoxOpen -eq $true) {
        return
    }
        if (($Script:GUICurrentStatus.CurrentWindow -eq 'DiskPartition') -and ($WPF_DP_GPTMBR_GroupBox.Visibility -eq 'Visible')){
            $MouseCoordinates = Get-MouseCoordinatesRelativetoWindow
            $Script:GUICurrentStatus.MousePositionXatTimeofPress = $MouseCoordinates.MousePositionRelativetoWindowX
            $Script:GUICurrentStatus.MousePositionYatTimeofPress = $MouseCoordinates.MousePositionRelativetoWindowY
            #Write-debug "X (At time of Button press):$($Script:GUICurrentStatus.MousePositionXatTimeofPress) Y (At time of Button press):$($Script:GUICurrentStatus.MousePositionYatTimeofPress)"                                
            if ($Script:GUICurrentStatus.PartitionHoveredOver){
                if ($Script:GUICurrentStatus.PartitionHoveredOver.PartitionType -eq 'MBR' -or $Script:GUICurrentStatus.PartitionHoveredOver.PartitionType -eq 'GPT'){

                    if ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName -eq $Script:GUICurrentStatus.PartitionHoveredOver.PartitionName){
                        if ($Script:GUICurrentStatus.PartitionHoveredOver.ResizeZone){
                            $Script:GUICurrentStatus.ActionToPerform = "GPTMBR_$($Script:GUICurrentStatus.PartitionHoveredOver.ResizeZone)"
                        }
                        else {
                            $Script:GUICurrentStatus.ActionToPerform = 'GPTMBR_Move' 
                        }
                        #Write-debug $Script:GUICurrentStatus.ActionToPerform                      
                    } 
                    if ($Script:GUICurrentStatus.PartitionHoveredOver.PartitionName -ne $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName){
                        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $Script:GUICurrentStatus.PartitionHoveredOver.Partition
                        $Script:GUICurrentStatus.ActionToPerform = $null
                        $Script:GUICurrentStatus.SelectedAmigaPartition = $null
                        #Write-debug "Selected MBR Partition:$($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName)"                       
                    }
                }
                elseif ($Script:GUICurrentStatus.PartitionHoveredOver.PartitionType -eq 'Amiga'){
                    if ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName -eq $Script:GUICurrentStatus.PartitionHoveredOver.PartitionName){
                        if ($Script:GUICurrentStatus.PartitionHoveredOver.ResizeZone){
                            $Script:GUICurrentStatus.ActionToPerform = "Amiga_$($Script:GUICurrentStatus.PartitionHoveredOver.ResizeZone)"
                        }
                        else {
                            $Script:GUICurrentStatus.ActionToPerform = 'Amiga_Move' 
                        }
                         #Write-debug $Script:GUICurrentStatus.ActionToPerform                      
                    } 
                    $Script:GUICurrentStatus.SelectedAmigaPartition = $Script:GUICurrentStatus.PartitionHoveredOver.Partition
                     #Write-debug "Selected Amiga Partition:$($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName)"                       
                }
            }
            else {
                if($Script:GUICurrentStatus.SelectedGPTMBRPartition -or $Script:GUICurrentStatus.SelectedAmigaPartition){
                    if  ($Script:GUICurrentStatus.SelectedAmigaPartition){
                        $Script:GUICurrentStatus.SelectedAmigaPartition = $null
                        
                        #Write-debug "Unselected Amiga Partition"                       

                    }
                    else {
                        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
                        #Write-debug "Unselected MBR Partition"                       

                    }
                }
            }
        }

        Update-UI -HighlightSelectedPartitions -UpdateInputBoxes -freespacealert

    })
     
}
