
if (-not ($Script:GUIActions.AvailableScreenModesWB)){
    $Script:GUIActions.AvailableScreenModesWB = (Get-InputFileCSV -CSV 'ScreenModesWB')
}

$WPF_StartPage_WorkbenchOutput_RadioButtonNative.add_Checked({
    $Script:GUIActions.ScreenModeType = "Native"
    $WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
    
    update-ui -Emu68Settings -WBScreenModeChangeType
})

$WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 1
$Script:GUIActions.ScreenModeType = "Native"
$WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 0
    