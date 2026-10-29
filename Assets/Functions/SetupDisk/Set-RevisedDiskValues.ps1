function Set-RevisedDiskValues {
    param (
        $SizeBytes
    )
    
    $PartitionsToCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries
    $DiskFreeSpaceSize = (Get-ConvertedSize -Size (($PartitionsToCheck[$PartitionsToCheck.Count-1]).BytesAvailableRight) -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2).size
    $NewSizeBytes = $SizeBytes
    if ( $NewSizeBytes -ge ($WPF_DP_Disk_GPTMBR.DiskSizeBytes -$DiskFreeSpaceSize)){
        $WPF_DP_Disk_GPTMBR.DiskSizeBytes = $NewSizeBytes
        $WPF_DP_Disk_GPTMBR.BytestoPixelFactor = ($WPF_DP_Disk_GPTMBR.DiskSizeBytes -$WPF_DP_Disk_GPTMBR.MGPTMBROverheadBytes) /$WPF_DP_Disk_GPTMBR.DiskSizePixels 

        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries  | ForEach-Object {
            $LeftMargin = $_.Partition.StartingPositionBytes/$WPF_DP_Disk_GPTMBR.BytestoPixelFactor
            $SizePixels = $_.Partition.PartitionSizeBytes/$WPF_DP_Disk_GPTMBR.BytestoPixelFactor
            if ($SizePixels -gt 4){
                $SizePixels -= 4
            }
            $_.Partition.Margin = [System.Windows.Thickness]"$LeftMargin,0,0,0"
            $_.Partition.ColumnDefinitions[1].Width = $SizePixels
         
        }
    }   

    $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
    $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)

}