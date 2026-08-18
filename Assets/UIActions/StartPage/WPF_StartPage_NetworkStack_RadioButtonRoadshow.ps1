$WPF_StartPage_NetworkStack_RadioButtonRoadshow.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }
    $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
    $Script:GUIActions.NetworkStack = "Roadshow"
    $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
    $WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 0
    $WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
})

$WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
$WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 0
$WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
$WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 1
