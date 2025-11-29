$WPF_StartPage_WorkbenchColour_Slider.add_ValueChanged({
    $Script:GUIActions.ScreenModeWBColourDepth = $WPF_StartPage_WorkbenchColour_Slider.Value
    $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth) 
    
})