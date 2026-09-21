$WPF_StartPage_OverclockSD_Slider.add_ValueChanged({
    $WPF_StartPage_OverclockSD_Value.Text = $WPF_StartPage_OverclockSD_Slider.Value
    $Script:GUIActions.SDOverClockSpeed = $WPF_StartPage_OverclockSD_Slider.Value
    $WPF_StartPage_OverclockSD_Value.Text = $Script:GUIActions.SDOverClockSpeed
    update-ui -Emu68Settings

})