$WPF_DP_Button_RemoveFreeSpace.add_click({

    Remove-GPTMBRFreeSpaceBetweenPartitions
    update-ui -FreeSpaceAlert    

})
