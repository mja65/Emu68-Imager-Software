function Add-InitialGPTMBRDisk {
    param (
        $DiskSizeBytes,
        $DiskType
    )
    
    if (-not $WPF_DP_Disk_GPTMBR){

        $MBRSectorAdjustmentBytes = $DiskSizeBytes - (Get-MBRNearestSizeBytes -RoundDown -SizeBytes $DiskSizeBytes) 
        # Write-debug "Rounded down disksize by: $MBRSectorAdjustmentBytes"

        $Script:WPF_DP_Disk_GPTMBR = New-GUIDisk -DiskType $DiskType
        $Script:WPF_DP_DiskGrid_GPTMBR.AddChild($WPF_DP_Disk_GPTMBR)      
        $Script:WPF_DP_Disk_GPTMBR.LeftDiskBoundary = 0 
        $Script:WPF_DP_Disk_GPTMBR.RightDiskBoundary = $LeftDiskBoundary + $Script:WPF_DP_Disk_GPTMBR.Children[0].Width
        $Script:WPF_DP_Disk_GPTMBR.DiskSizePixels =  $WPF_DP_Disk_GPTMBR.RightDiskBoundary-$WPF_DP_Disk_GPTMBR.LefttDiskBoundary
        # Write-host "Function Add-InitialGPTMBRDisk: DiskSizeBytes is: $DiskSizeBytes" 
        $Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes =  $DiskSizeBytes 
        $Script:WPF_DP_Disk_GPTMBR.GPTMBROverheadBytes += $MBRSectorAdjustmentBytes 
        $Script:WPF_DP_Disk_GPTMBR.BytestoPixelFactor = ($Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes - $Script:WPF_DP_Disk_GPTMBR.GPTMBROverheadBytes) /$Script:WPF_DP_Disk_GPTMBR.DiskSizePixels
    }
}
