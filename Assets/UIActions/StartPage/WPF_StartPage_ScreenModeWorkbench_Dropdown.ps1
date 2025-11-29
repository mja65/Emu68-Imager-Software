# $Script:GUIActions.AvailableScreenModesWB = Get-InputCSVs -ScreenModesWB
# foreach ($ScreenMode in $Script:GUIActions.AvailableScreenModesWB) {
#     $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($ScreenMode.FriendlyName)
# }

$WPF_StartPage_ScreenModeWorkbench_Dropdown.Add_SelectionChanged({
    if ($WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem) {
        if ($WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem -ne $Script:GUIActions.ScreenModetoUseWB){
            $Script:GUIActions.ScreenModetoUseWB = $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem
            $Script:GUIActions.ScreenModeWBColourDepth = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.FriendlyName -eq $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem}).DefaultDepth
            $WPF_StartPage_WorkbenchColour_Slider.Value = $Script:GUIActions.ScreenModeWBColourDepth 
            $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)        
        }
    }
}) 