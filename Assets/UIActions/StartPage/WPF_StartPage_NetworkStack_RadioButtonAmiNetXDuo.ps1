$WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }
    $Script:GUIActions.NetworkStack = "AmiNetXDuo"
    $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
    $WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 0
    $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
    $WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
})
