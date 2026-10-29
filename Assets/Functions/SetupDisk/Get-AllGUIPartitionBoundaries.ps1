function Get-AllGUIPartitionBoundaries {
    param (
        [Switch]$GPTMBR,
        [Switch]$Amiga

    )
       
    $DiskPartitionGridMargins = $WPF_Partition.Margin
    $AllPartitionBoundaries = [System.Collections.Generic.List[PSCustomObject]]::New()

    if ($GPTMBR){
        $GroupBoxGPTMBRMargins = $WPF_DP_GPTMBR_GroupBox.Margin
        $DiskGridGPTMBRMargins = $WPF_DP_DiskGrid_GPTMBR.Margin
        $GPTMBRLeftMargin = $DiskPartitionGridMargins.Left + $GroupBoxGPTMBRMargins.Left + $DiskGridGPTMBRMargins.Left
        $GPTMBRTopMargin = $DiskPartitionGridMargins.Top + $GroupBoxGPTMBRMargins.Top + $DiskGridGPTMBRMargins.Top
        $AllPartitionBoundaries_MBR = [System.Collections.Generic.List[PSCustomObject]]::New()        

        Get-AllGUIPartitions -PartitionType $Script:GUIActions.DiskType | ForEach-Object {   
            $PartitionType = $Script:GUIActions.DiskType
            $LeftMarginWindow = $GPTMBRLeftMargin + $_.Value.Margin.Left
            $TopMarginWindow = $GPTMBRTopMargin 
            $RightMarginWindow = $GPTMBRLeftMargin + $_.Value.Margin.Left + (Get-GUIPartitionWidth -Partition $_.Value)
            $BottomMarginWindow = $GPTMBRTopMargin  + $_.Value.ActualHeight
     
            $AllPartitionBoundaries_MBR.add([PSCustomObject]@{
                PartitionName = $_.Name
                Partition = $_.Value
                PartitionType = $PartitionType
                PartitionSubType = $_.Value.PartitionSubType
                ImportedFilesPath = $_.Value.ImportedFilesPath 
                CanMove = $_.Value.CanMove
                CanDelete = $_.Value.CanDelete
                CanResizeLeft = $_.Value.CanResizeLeft
                CanResizeRight = $_.Value.CanResizeRight
                BytesAvailableLeft = $null
                BytesAvailableRight = $null
                PixelsAvailableLeft = $null
                PixelsAvailableRight = $null
                StartingPositionBytes = [int64]$_.Value.StartingPositionBytes
                StartingPositionSector = [int64]$_.Value.StartingPositionSector
                PartitionSizeBytes = [int64]$_.Value.PartitionSizeBytes
                EndingPositionBytes = [int64]($_.Value.StartingPositionBytes + $_.Value.PartitionSizeBytes)
                LeftMargin = $_.Value.Margin.Left
                LeftMarginWindow = $LeftMarginWindow
                Width = Get-GUIPartitionWidth -Partition $_.Value 
                ExpectedWidth = $_.Value.PartitionSizeBytes/ $WPF_DP_Disk_GPTMBR.BytestoPixelFactor
                OverhangPixels = ($_.Value.PartitionSizeBytes/ $WPF_DP_Disk_GPTMBR.BytestoPixelFactor) - (Get-GUIPartitionWidth -Partition $_.Value)
                OverhangPixelsAccumulated = $null
                RightMargin = ($_.Value.Margin.Left) + (Get-GUIPartitionWidth -Partition $_.Value)
                RightMarginWindow = $RightMarginWindow
                TopMargin = $_.Value.Margin.Top
                TopMarginWindow = $TopMarginWindow
                Height = $_.Value.ActualHeight
                BottomMargin = $_.Value.Margin.Top + $_.Value.ActualHeight
                BottomMarginWindow = $BottomMarginWindow
            })
        }
     
        $AllPartitionBoundaries_MBR_Sorted = $AllPartitionBoundaries_MBR | Sort-Object {[int64]$_.StartingPositionBytes}
     
        $AllPartitionBoundaries_MBR = [System.Collections.Generic.List[PSCustomObject]]::new()
     
        $AllPartitionBoundaries_MBR_Sorted | ForEach-Object {
            $AllPartitionBoundaries_MBR.add($_)
        }
        
        $OverhangPixelsAccumulated = 0
     
        for ($i = 0; $i -lt $AllPartitionBoundaries_MBR.Count; $i++) {
            $OverhangPixelsAccumulated += $AllPartitionBoundaries_MBR[$i].OverhangPixels
            $AllPartitionBoundaries_MBR[$i].OverhangPixelsAccumulated = $OverhangPixelsAccumulated 
            if ($i -eq 0){
                $AllPartitionBoundaries_MBR[$i].BytesAvailableLeft = $AllPartitionBoundaries_MBR[$i].StartingPositionBytes
                $AllPartitionBoundaries_MBR[$i].PixelsAvailableLeft = $AllPartitionBoundaries_MBR[$i].LeftMargin
            }
            else{
                $AllPartitionBoundaries_MBR[$i].BytesAvailableLeft = $AllPartitionBoundaries_MBR[$i].StartingPositionBytes - $AllPartitionBoundaries_MBR[$i-1].EndingPositionBytes
                $AllPartitionBoundaries_MBR[$i].PixelsAvailableLeft = $AllPartitionBoundaries_MBR[$i].LeftMargin - $AllPartitionBoundaries_MBR[$i-1].RightMargin
            }
            if (($i+1) -lt $AllPartitionBoundaries_MBR.Count){
                $AllPartitionBoundaries_MBR[$i].PixelsAvailableRight = $AllPartitionBoundaries_MBR[$i+1].LeftMargin-$AllPartitionBoundaries_MBR[$i].RightMargin
                $AllPartitionBoundaries_MBR[$i].BytesAvailableRight = $AllPartitionBoundaries_MBR[$i+1].StartingPositionBytes-$AllPartitionBoundaries_MBR[$i].EndingPositionBytes
            }
            else{
                $AllPartitionBoundaries_MBR[$i].PixelsAvailableRight = $WPF_DP_Disk_GPTMBR.RightDiskBoundary - $AllPartitionBoundaries_MBR[$i].RightMargin
                $AllPartitionBoundaries_MBR[$i].BytesAvailableRight =  $WPF_DP_Disk_GPTMBR.DiskSizeBytes - $WPF_DP_Disk_GPTMBR.GPTMBROverheadBytes - $AllPartitionBoundaries_MBR[$i].EndingPositionBytes
            }                  
        }
        
        $AllPartitionBoundaries_MBR | ForEach-Object {
            $AllPartitionBoundaries.Add($_)
        }
        
    }
       
    if ($Amiga){
        $GroupBoxAmigaMargins = $WPF_DP_Amiga_GroupBox.Margin
        $DiskGridAmigaMargins = $WPF_DP_DiskGrid_Amiga.Margin
        $AmigaLeftMargin = $DiskPartitionGridMargins.Left + $GroupBoxAmigaMargins.Left + $DiskGridAmigaMargins.Left 
        $AmigaTopMargin = $DiskPartitionGridMargins.Top + $GroupBoxAmigaMargins.Top + $DiskGridAmigaMargins.Top 
        $AllPartitionBoundaries_Amiga_Preliminary = [System.Collections.Generic.List[PSCustomObject]]::New()

        Get-AllGUIPartitions -PartitionType 'Amiga' | ForEach-Object {
            $PartitionType = 'Amiga'
            $LeftMarginWindow = $AmigaLeftMargin + $_.Value.Margin.Left
            $TopMarginWindow = $AmigaTopMargin 
            $RightMarginWindow = $AmigaLeftMargin + $_.Value.Margin.Left + (Get-GUIPartitionWidth -Partition $_.Value)
            $BottomMarginWindow = $AmigaTopMargin  + $_.Value.ActualHeight
            $AmigaDiskName = ($_.Name.Substring(0,($_.Name.IndexOf('_AmigaDisk_')+10)))
            $AllPartitionBoundaries_Amiga_Preliminary.add([PSCustomObject]@{
                PartitionName = $_.Name
                Partition = $_.Value
                PartitionType = $PartitionType
                ImportedFilesPath = $_.Value.ImportedFilesPath 
                CanMove = $_.Value.CanMove
                CanDelete = $_.Value.CanDelete
                CanResizeLeft = $_.Value.CanResizeLeft
                CanResizeRight = $_.Value.CanResizeRight
                BytesAvailableLeft = $null
                BytesAvailableRight = $null
                PixelsAvailableLeft = $null
                PixelsAvailableRight = $null
                StartingPositionBytes = $_.Value.StartingPositionBytes
                PartitionSizeBytes = $_.Value.PartitionSizeBytes
                EndingPositionBytes = $_.Value.StartingPositionBytes + $_.Value.PartitionSizeBytes
                LeftMargin = $_.Value.Margin.Left
                LeftMarginWindow = $LeftMarginWindow
                Width = Get-GUIPartitionWidth -Partition $_.Value 
                ExpectedWidth = $_.Value.PartitionSizeBytes/ (Get-Variable -name $AmigaDiskName).value.BytestoPixelFactor 
                OverhangPixels = (Get-GUIPartitionWidth -Partition $_.Value) - ($_.Value.PartitionSizeBytes/ (Get-Variable -name $AmigaDiskName).value.BytestoPixelFactor) 
                OverhangPixelsAccumulated = $null
                RightMargin = ($_.Value.Margin.Left) + (Get-GUIPartitionWidth -Partition $_.Value)
                RightMarginWindow = $RightMarginWindow
                TopMargin = $_.Value.Margin.Top
                TopMarginWindow = $TopMarginWindow
                Height = $_.Value.ActualHeight
                BottomMargin = $_.Value.Margin.Top + $_.Value.ActualHeight
                BottomMarginWindow = $BottomMarginWindow
            })
        }
        
        $Sorted_Amiga_Preliminary = $AllPartitionBoundaries_Amiga_Preliminary | Sort-Object {[int64]$_.StartingPositionBytes}

        # Create a new list and add the sorted items
        
        $AllPartitionBoundaries_Amiga_Preliminary = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        $Sorted_Amiga_Preliminary | ForEach-Object { 
            $AllPartitionBoundaries_Amiga_Preliminary.Add($_) 
        }

        $AllPartitionBoundaries_Amiga = [System.Collections.Generic.List[PSCustomObject]]::New()

        $AmigaDisks = (get-variable -name "WPF*" | Where-Object {$_.Value.DiskType -eq 'Amiga'}).Name  
    
        foreach ($AmigaDisk in $AmigaDisks) {
            $OverhangPixelsAccumulated = 0
            $PartitionstoCheck = @($AllPartitionBoundaries_Amiga_Preliminary | Where-Object {$_.PartitionName -match $AmigaDisk})
            for ($i = 0; $i -lt $PartitionstoCheck.Count; $i++){
                $OverhangPixelsAccumulated += $PartitionstoCheck[$i].OverhangPixels
                $PartitionstoCheck[$i].OverhangPixelsAccumulated = $OverhangPixelsAccumulated             
                if ($i -eq 0){
                    $PartitionstoCheck[$i].BytesAvailableLeft = $PartitionstoCheck[$i].StartingPositionBytes 
                    $PartitionstoCheck[$i].PixelsAvailableLeft = $PartitionstoCheck[$i].LeftMargin
                }
                else {
                    $PartitionstoCheck[$i].BytesAvailableLeft = $PartitionstoCheck[$i].StartingPositionBytes - $PartitionstoCheck[$i-1].EndingPositionBytes
                    $PartitionstoCheck[$i].PixelsAvailableLeft = $PartitionstoCheck[$i].LeftMargin - $PartitionstoCheck[$i-1].RightMargin
                }
                if (($i+1) -lt $PartitionstoCheck.count){
                    $PartitionstoCheck[$i].PixelsAvailableRight = $PartitionstoCheck[$i+1].LeftMargin-$PartitionstoCheck[$i].RightMargin
                    $PartitionstoCheck[$i].BytesAvailableRight = $PartitionstoCheck[$i+1].StartingPositionBytes-$PartitionstoCheck[$i].EndingPositionBytes
                }
                else {
                    $PartitionstoCheck[$i].PixelsAvailableRight = (Get-Variable -name $AmigaDisk).Value.RightDiskBoundary - $PartitionstoCheck[$i].RightMargin
                    $PartitionstoCheck[$i].BytesAvailableRight =  (Get-Variable -name $AmigaDisk).Value.DiskSizeBytes - $PartitionstoCheck[$i].EndingPositionBytes
                }
    
            }
            $PartitionstoCheck | ForEach-Object {
                $AllPartitionBoundaries_Amiga.Add($_)         
            }
    
        }
        
        $AllPartitionBoundaries_Amiga | ForEach-Object {
            $AllPartitionBoundaries.Add($_)
        }            
            
    }
    
    return $AllPartitionBoundaries
    
}

