$WPF_DP_Button_SetImageSize.add_click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    if ($Script:GUIActions.ImageSizeSelected -eq $true){
        $null = Show-WarningorError -Msg_Header 'Image Size Set' -Msg_Body 'You have already set the image size. If you wish to change you will need to reset the disk!' -BoxTypeError -ButtonType_OK
        return
    }

    $SizeofImage = Get-NewImageSize -DefaultScale "GiB"
    if ($SizeofImage) {
        Set-InitialDiskValues -DiskType $WPF_DP_Disk_Type_DropDown.SelectedItem -SizeBytes $SizeofImage 
        $Script:GUIActions.ImageSizeSelected = $true
        Update-UI -DiskPartitionWindow -freespacealert
    }
    else {
        $Script:GUIActions.ImageSizeSelected = $null
    }
    return

})