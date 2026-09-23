$WPF_EditUnicamSettingsWindow_OK_Button.Add_Click({
    
    if ($WPF_EditUnicamSettingsWindow_Unicam_StartBoot_checkBox.IsChecked -eq $true){
        $Script:GUIActions.UnicamStartonBoot = $true
    }
    else {
    $Script:GUIActions.UnicamStartonBoot = $false
    }
    
    if ($WPF_EditUnicamSettingsWindow_Unicam_IntegerScaling_radioButton.IsChecked -eq $true){
        $Script:GUIActions.UnicamScalingType = "Integer"
    }
    elseif ($WPF_EditUnicamSettingsWindow_Unicam_SmoothScaling_radioButton.IsChecked -eq $true){
        $Script:GUIActions.UnicamScalingType = "Smooth"
    }
       
    #$Script:GUIActions.UnicamPhase = $WPF_EditUnicamSettingsWindow_Phase_Input.Text
    $Script:GUIActions.UnicamBParameter = $WPF_EditUnicamSettingsWindow_B_Parameter_Input.Text
    $Script:GUIActions.UnicamCParameter = $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text
    #$Script:GUIActions.UnicamAspectRatio =  $WPF_EditUnicamSettingsWindow_Aspect_Input.Text
    #$Script:GUIActions.UnicamSizeX = $WPF_EditUnicamSettingsWindow_Size_X_Input.Text
    #$Script:GUIActions.UnicamSizeY = $WPF_EditUnicamSettingsWindow_Size_Y_Input.Text
    #$Script:GUIActions.UnicamOffsetX = $WPF_EditUnicamSettingsWindow_offset_X_Input.Text
    #$Script:GUIActions.UnicamOffsetY = $WPF_EditUnicamSettingsWindow_offset_Y_Input.Text
    $Script:GUIActions.UnicamScanLinesNonLaced = $WPF_EditUnicamSettingsWindow_Scanlines_slider.Value
    $Script:GUIActions.UnicamScanLinesLaced = $WPF_EditUnicamSettingsWindow_ScanlinesInterlaced_slider.Value

    $null = $WPF_EditUnicamSettingsWindow.Close()
    
})