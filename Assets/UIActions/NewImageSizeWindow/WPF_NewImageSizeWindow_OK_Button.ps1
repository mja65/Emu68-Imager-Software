$WPF_NewImageSizeWindow_OK_Button.Add_Click({
    if (-not ($WPF_NewImageSizeWindow_Input_ImageSize_Value.Text)){
        $WPF_NewImageSizeWindow_ErrorMessage_Label.Text = "No value entered!"
        return
    }
    if ((Get-IsValueNumber -TexttoCheck $WPF_NewImageSizeWindow_Input_ImageSize_Value.Text) -eq $false){
        $WPF_NewImageSizeWindow_ErrorMessage_Label.Text = "Size of image must be a number!"
        return
    }

    $Script:GUICurrentStatus.ImageSizeAcceptedValue = $true
    $null = $WPF_NewImageSizeWindow.Close()

})
 