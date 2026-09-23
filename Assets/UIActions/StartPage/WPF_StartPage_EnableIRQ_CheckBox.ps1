$WPF_StartPage_EnableIRQ_CheckBox.add_Checked({
    $Script:GUIActions.IRQEnabled = $true
    Update-UI -Emu68Settings
})  

$WPF_StartPage_EnableIRQ_CheckBox.add_UnChecked({
    $Script:GUIActions.IRQEnabled = $false  
    Update-UI -Emu68Settings  
})

$Script:GUIActions.IRQEnabled = $false