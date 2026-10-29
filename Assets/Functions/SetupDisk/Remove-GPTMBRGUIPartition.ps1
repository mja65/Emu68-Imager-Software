function Remove-GPTMBRGUIPartition {
    param (
        $Partition
    )
    # $PartitionName = 'WPF_DP_Partition_MBR_2'
    if ($Partition.CanDelete -eq $false) {
        return $false
    }
    else{
        $WPF_DP_Disk_GPTMBR.NumberofPartitionsGPTMBR -= 1   
        $WPF_DP_DiskGrid_GPTMBR.Children.Remove($Partition)
        Remove-Variable -Scope Script -Name $Partition.PartitionName
        $WPF_DP_DiskGrid_GPTMBR.UpdateLayout()
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)
        return $true
    }

}
