$WPF_StartPage_LowSpeed_CheckBox.add_Checked({
    $Script:GUIActions.SDLowSpeed = $true
    $Script:GUIActions.SDOverClock = $false
    Update-UI -Emu68Settings
})

$WPF_StartPage_LowSpeed_CheckBox.add_UnChecked({
    $Script:GUIActions.SDLowSpeed = $false
})

$Script:GUIActions.SDLowSpeed = $true