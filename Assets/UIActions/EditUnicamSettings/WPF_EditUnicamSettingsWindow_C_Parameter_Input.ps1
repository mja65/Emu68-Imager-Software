$WPF_EditUnicamSettingsWindow_C_Parameter_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){
        if ((Get-IsValueNumber -TexttoCheck $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text -IntegerValue) -eq $false){
            $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Background = "Red"
        }
        else {
            if (([int64]$WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text -gt $WPF_EditUnicamSettingsWindow_C_Parameter_slider.Maximum) -or  ([int64]$WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text -lt $WPF_EditUnicamSettingsWindow_C_Parameter_slider.Minimum)){
                $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Background = "Yellow"
            }
            else {
                $WPF_EditUnicamSettingsWindow_C_Parameter_slider.value = $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text
            }
        }
    }       
})