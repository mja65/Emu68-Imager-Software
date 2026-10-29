$WPF_DP_MBRPartitionSelect_RightArrow.add_click({
    $Script:GUICurrentStatus.SelectedGPTMBRPartition = (Get-NextGUIPartition -Side 'Right' -PartitiontoCheck $Script:GUICurrentStatus.SelectedGPTMBRPartition -PartitionType $Script:GUIActions.DiskType)
    update-ui -HighlightSelectedPartitions -UpdateInputBoxes
})