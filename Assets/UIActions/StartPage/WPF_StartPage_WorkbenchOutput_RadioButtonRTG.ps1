$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
$WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 1

if (-not ($Script:GUIActions.AvailableScreenModesWB)){
    $Script:GUIActions.AvailableScreenModesWB = (Get-InputFileCSV -CSV 'ScreenModes')
}

$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.add_Checked({
    $WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 0
    $Script:GUIActions.ScreenModeType = "RTG"
           
    update-ui -Emu68Settings -WBScreenModeChangeType

})