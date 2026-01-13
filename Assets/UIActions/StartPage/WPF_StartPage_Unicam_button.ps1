$WPF_StartPage_Unicam_button.Add_Click({
    
    Remove-Variable -Name 'WPF_EditUnicamSettingsWindow_*'
    
    $WPF_EditUnicamSettingsWindow = Get-XAML -WPFPrefix 'WPF_EditUnicamSettingsWindow_' -XMLFile '.\Assets\WPF\Window_EditUnicamSettings.xaml'  -ActionsPath '.\Assets\UIActions\EditUnicamSettings\' -AddWPFVariables

    if ($Script:GUIActions.UnicamStartonBoot) {
        $WPF_EditUnicamSettingsWindow_Unicam_StartBoot_checkBox.IsChecked = 1
    }
    if ($Script:GUIActions.UnicamScalingType -eq "Smooth"){
        $WPF_EditUnicamSettingsWindow_Unicam_SmoothScaling_radioButton.IsChecked =1
        #$WPF_EditUnicamSettingsWindow_Unicam_Phase_Groupbox.Visibility = "Visible"  
        $WPF_EditUnicamSettingsWindow_Unicam_B_Parameter_Groupbox.Visibility = "Visible"
        $WPF_EditUnicamSettingsWindow_Unicam_C_Parameter_Groupbox.Visibility = "Visible"        
    }
    elseif ($Script:GUIActions.UnicamScalingType -eq "Integer"){
        $WPF_EditUnicamSettingsWindow_Unicam_IntegerScaling_radioButton.IsChecked =1    
        #$WPF_EditUnicamSettingsWindow_Unicam_Phase_Groupbox.Visibility = "Visible"      
        $WPF_EditUnicamSettingsWindow_Unicam_B_Parameter_Groupbox.Visibility = "Hidden"
        $WPF_EditUnicamSettingsWindow_Unicam_C_Parameter_Groupbox.Visibility = "Hidden"
    }

    # $WPF_EditUnicamSettingsWindow_Phase_Input.Text = $Script:GUIActions.UnicamPhase 
    # $WPF_EditUnicamSettingsWindow_Phase_slider.Value = $Script:GUIActions.UnicamPhase 
    $WPF_EditUnicamSettingsWindow_B_Parameter_Input.Text = $Script:GUIActions.UnicamBParameter
    $WPF_EditUnicamSettingsWindow_B_Parameter_slider.Value = $Script:GUIActions.UnicamBParameter
    $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text = $Script:GUIActions.UnicamCParameter
    $WPF_EditUnicamSettingsWindow_C_Parameter_slider.Value = $Script:GUIActions.UnicamCParameter

    $WPF_EditUnicamSettingsWindow_Unicam_Size_Groupbox.Visibility = "Hidden"
    $WPF_EditUnicamSettingsWindow_Unicam_Offset_Groupbox.Visibility = "Hidden"
    # $Script:GUIActions.UnicamSizeXPosition = $null
    # $Script:GUIActions.UnicamSizeYPosition = $null
    # $Script:GUIActions.UnicamOffsetXPosition = $null
    # $Script:GUIActions.UnicamOffsetYPosition = $null


    $WPF_EditUnicamSettingsWindow.ShowDialog() | out-null
    
    $WPF_EditUnicamSettingsWindow.close()
    
})