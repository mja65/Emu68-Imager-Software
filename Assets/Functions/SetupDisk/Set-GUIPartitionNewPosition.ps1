function Set-GUIPartitionNewPosition {
    param (
        $Partition,
        $PartitionType,
        $AmountMovedPixels,
        $AmountMovedBytes
    )
    
  
    If (-not ($Partition)){
        return
    }

    # $PartitionName = 'WPF_DP_Partition_MBR_3'
    # $PartitionName = 'WPF_DP_Partition_MBR_3_AmigaDisk_Partition_6'
    # $AmountMovedBytes = 10240000
    
    # Write-debug "Function Set-GUIPartitionNewPosition PartitionName:$PartitionName AmountMovedBytes:$AmountMovedBytes AmountMovedPixels:$AmountMovedPixels"
    
    if ($Partition.CanMove -eq $false) {
        return $false
    }

    $PartitionBoundary = Get-AllGUIPartitionBoundaries -GPTMBR -Amiga | Where-Object {$_.PartitionName -eq $Partition.PartitionName}

    if ($PartitionType -eq 'MBR' -or $PartitionType -eq 'GPT'){
        $BytestoPixelFactor = $WPF_DP_Disk_GPTMBR.BytestoPixelFactor
    }
    elseif ($PartitionType -eq 'Amiga'){
        $AmigaDiskName = $Partition.PartitionName.Substring(0,($Partition.PartitionName.IndexOf('_AmigaDisk_Partition_')+10))
        $BytestoPixelFactor = (Get-Variable -name $AmigaDiskName).Value.BytestoPixelFactor 
    }

    if ($AmountMovedPixels){
        if ($AmountMovedPixels -gt 0){
            # Write-debug "Available bytes Right is :$($PartitionBoundary.BytesAvailableRight) $($PartitionBoundary.PixelsAvailableRight)"
            if (($BytestoPixelFactor*$AmountMovedPixels) -gt $PartitionBoundary.BytesAvailableRight) {
                $AmountMovedPixels = $PartitionBoundary.BytesAvailableRight/$BytestoPixelFactor
                
            }
        }
        elseif ($AmountMovedPixels -lt 0){
            # Write-debug "Available bytes left is: $($PartitionBoundary.BytesAvailableLeft). Available pixels left is: $($PartitionBoundary.PixelsAvailableLeft)"
            if (($BytestoPixelFactor*$AmountMovedPixels*-1) -gt $PartitionBoundary.BytesAvailableLeft) {
                $AmountMovedPixels = ($PartitionBoundary.BytesAvailableLeft/$BytestoPixelFactor*-1)
            }
        }
        $AmountMovedBytes = $BytestoPixelFactor*$AmountMovedPixels

    }
    elseif ($AmountMovedBytes){
        $AmountMovedPixels = $AmountMovedBytes/$BytestoPixelFactor
    }
   
    $AmounttoSetLeft = $Partition.Margin.Left + $AmountMovedPixels
        
    $Partition.Margin = [System.Windows.Thickness]"$AmounttoSetLeft,0,0,0"
    $Partition.StartingPositionBytes = $Partition.StartingPositionBytes + $AmountMovedBytes
    if ($PartitionType -eq 'MBR' -or $PartitionType -eq 'GPT'){
        $Partition.StartingPositionSector = $Partition.StartingPositionBytes/$Script:Settings.MBRSectorSizeBytes
    }
    $WPF_MainWindow.UpdateLayout()

    if ($PartitionType -eq 'Amiga'){
        if ($WPF_DP_Amiga_GroupBox.Visibility -eq 'Visible'){      
            $WPF_DP_DiskGrid_Amiga.UpdateLayout()
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }

    }
    elseif ($PartitionType -eq 'MBR' -or $PartitionType -eq 'GPT'){
        $WPF_DP_DiskGrid_GPTMBR.UpdateLayout()
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)
            
    }
         
    return $true
    
}
