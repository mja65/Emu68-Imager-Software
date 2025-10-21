    $WPF_NewImageSizeWindow_Cancel_Button.Add_Click({
    $WPF_NewImageSizeWindow_Input_ImageSize_Value.Text = $null  
    $Script:GUICurrentStatus.ImageSizeAcceptedValue= $false 
    $null = $WPF_NewImageSizeWindow.close()
})