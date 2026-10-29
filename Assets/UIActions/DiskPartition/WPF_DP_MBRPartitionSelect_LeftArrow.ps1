$WPF_DP_MBRPartitionSelect_LeftArrow.add_click({
    $Script:GUICurrentStatus.SelectedGPTMBRPartition = (Get-NextGUIPartition -Side 'Left' -PartitiontoCheck $Script:GUICurrentStatus.SelectedGPTMBRPartition -PartitionType $Script:GUIActions.DiskType)
    update-ui -HighlightSelectedPartitions -UpdateInputBoxes
})