$WPF_StartPage_Unicam_button.Add_Click({
    
    Remove-Variable -Name 'WPF_EditUnicamSettingsWindow_*'
    
    $WPF_EditUnicamSettingsWindow = Get-XAML -WPFPrefix 'WPF_EditUnicamSettingsWindow_' -XMLFile '.\Assets\WPF\Window_EditUnicamSettings.xaml'  -ActionsPath '.\Assets\UIActions\EditUnicamSettings\' -AddWPFVariables

    if ($Script:GUIActions.UnicamStartonBoot) {
        $WPF_EditUnicamSettingsWindow_Unicam_StartBoot_checkBox.IsChecked = 1
    }
    if ($Script:GUIActions.Emu68VersionType -ne "Release"){
       $WPF_EditUnicamSettingsWindow_Unicam_Type_Groupbox.Visibility="Visible" 
    } 
    else {
       $WPF_EditUnicamSettingsWindow_Unicam_Type_Groupbox.Visibility="Hidden" 
    }
    if ($Script:GUIActions.UnicamDeviceType -eq "ft"){
        $WPF_EditUnicamSettingsWindow_Unicam_Type_FT_radioButton.IsChecked = 1         
    }
    elseif ($Script:GUIActions.UnicamDeviceType -eq "C790"){
        $WPF_EditUnicamSettingsWindow_Unicam_Type_C790_radioButton.IsChecked = 1 
    }
    if ($Script:GUIActions.UnicamScalingType -eq "Smooth"){
        $WPF_EditUnicamSettingsWindow_Unicam_SmoothScaling_radioButton.IsChecked = 1
        #$WPF_EditUnicamSettingsWindow_Unicam_Phase_Groupbox.Visibility = "Visible"  
        $WPF_EditUnicamSettingsWindow_Unicam_B_Parameter_Groupbox.Visibility = "Visible"
        $WPF_EditUnicamSettingsWindow_Unicam_C_Parameter_Groupbox.Visibility = "Visible"        
    }
    elseif ($Script:GUIActions.UnicamScalingType -eq "Integer"){
        $WPF_EditUnicamSettingsWindow_Unicam_IntegerScaling_radioButton.IsChecked = 1    
        #$WPF_EditUnicamSettingsWindow_Unicam_Phase_Groupbox.Visibility = "Visible"      
        $WPF_EditUnicamSettingsWindow_Unicam_B_Parameter_Groupbox.Visibility = "Hidden"
        $WPF_EditUnicamSettingsWindow_Unicam_C_Parameter_Groupbox.Visibility = "Hidden"
    }

    if (($Script:GUIActions.UnicamScanLinesNonLaced) -or ($Script:GUIActions.UnicamScanLinesLaced)){
        $WPF_EditUnicamSettingsWindow_Unicam_EnableScanLines_checkBox.IsChecked = 1
        $WPF_EditUnicamSettingsWindow_Unicam_Scanlines_Groupbox.Visibility = "Visible"
        $WPF_EditUnicamSettingsWindow_Scanlines_slider.Value = $Script:GUIActions.UnicamScanLinesNonLaced
        $WPF_EditUnicamSettingsWindow_Scanlines_value.text = $Script:GUIActions.UnicamScanLinesNonLaced
        $WPF_EditUnicamSettingsWindow_ScanlinesInterlaced_slider.Value = $Script:GUIActions.UnicamScanLinesLaced
        $WPF_EditUnicamSettingsWindow_ScanlinesInterlaced_value.text = $Script:GUIActions.UnicamScanLinesLaced
    }
    else {
        $WPF_EditUnicamSettingsWindow_Unicam_EnableScanLines_checkBox.IsChecked = 0
        $WPF_EditUnicamSettingsWindow_Unicam_Scanlines_Groupbox.Visibility = "Hidden"
    }

    # $WPF_EditUnicamSettingsWindow_Phase_Input.Text = $Script:GUIActions.UnicamPhase 
    # $WPF_EditUnicamSettingsWindow_Phase_slider.Value = $Script:GUIActions.UnicamPhase 
    $WPF_EditUnicamSettingsWindow_B_Parameter_Input.Text = $Script:GUIActions.UnicamBParameter
    $WPF_EditUnicamSettingsWindow_B_Parameter_slider.Value = $Script:GUIActions.UnicamBParameter
    $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text = $Script:GUIActions.UnicamCParameter
    $WPF_EditUnicamSettingsWindow_C_Parameter_slider.Value = $Script:GUIActions.UnicamCParameter
    
    $WPF_EditUnicamSettingsWindow_Unicam_Size_Groupbox.Visibility = "Hidden"
    $WPF_EditUnicamSettingsWindow_Unicam_Offset_Groupbox.Visibility = "Hidden"
    # $Script:GUIActions.UnicamSizeX = $null
    # $Script:GUIActions.UnicamSizeY = $null
    # $Script:GUIActions.UnicamOffsetX = $null
    # $Script:GUIActions.UnicamOffsetY = $null


    $WPF_EditUnicamSettingsWindow.ShowDialog() | out-null
    
    $WPF_EditUnicamSettingsWindow.close()
    
})