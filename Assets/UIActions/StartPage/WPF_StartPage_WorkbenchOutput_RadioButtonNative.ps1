
if (-not ($Script:GUIActions.AvailableScreenModesWB)){
    $Script:GUIActions.AvailableScreenModesWB = Get-InputCSVs -ScreenModesWB
}

$WPF_StartPage_WorkbenchOutput_RadioButtonNative.add_Checked({
    $Script:GUIActions.ScreenModeType = "Native"
    $WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
    $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
    $Script:GUIActions.AvailableScreenModesWB | Where-Object 'Type' -ne "RTG" | ForEach-Object {
        $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
        if ($_.DefaultMode -eq $true){
            $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $_.FriendlyName
            $WPF_StartPage_WorkbenchColour_Slider.Value = $_.DefaultDepth
        }
    }
    update-ui -Emu68Settings
})

$WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 1
$Script:GUIActions.ScreenModeType = "Native"
$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
    