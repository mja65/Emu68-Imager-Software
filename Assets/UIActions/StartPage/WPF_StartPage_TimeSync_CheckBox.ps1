$WPF_StartPage_TimeSync_CheckBox.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }

    $Script:GUIActions.AutomaticTimeSyncEnabled = $true
})

$WPF_StartPage_TimeSync_CheckBox.add_UnChecked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }

    $Script:GUIActions.AutomaticTimeSyncEnabled = $false
})

$WPF_StartPage_TimeSync_CheckBox.IsChecked = ($Script:GUIActions.AutomaticTimeSyncEnabled -eq $true)
