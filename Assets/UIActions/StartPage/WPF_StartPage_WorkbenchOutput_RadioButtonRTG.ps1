$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
$WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 1

if (-not ($Script:GUIActions.AvailableScreenModesWB)){
    $Script:GUIActions.AvailableScreenModesWB = Get-InputCSVs -ScreenModesWB
}

$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.add_Checked({
    $WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 0
    $Script:GUIActions.ScreenModeType = "RTG"
    $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
    $Script:GUIActions.AvailableScreenModesWB | Where-Object 'Type' -eq "RTG" | ForEach-Object {
        $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
        if ($_.DefaultMode -eq $true){
            $Script:GUIActions.ScreenModetoUseWB = $_.FriendlyName
            $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $_.FriendlyName
            $WPF_StartPage_WorkbenchColour_Slider.Value = $_.DefaultDepth
            $Script:GUIActions.ScreenModeWBColourDepth = $WPF_StartPage_WorkbenchColour_Slider.Value     
            $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)    
        }
    }
    
    update-ui -Emu68Settings

})