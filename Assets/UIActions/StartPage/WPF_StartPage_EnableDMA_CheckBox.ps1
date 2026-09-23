$WPF_StartPage_EnableDMA_CheckBox.add_Checked({
    $Script:GUIActions.DMAEnabled = $true
    $Script:GUIActions.IRQEnabled = $true
    Update-UI -Emu68Settings
})

$WPF_StartPage_EnableDMA_CheckBox.add_UnChecked({
    $Script:GUIActions.DMAEnabled = $false 
    $Script:GUIActions.IRQEnabled = $false 
    Update-UI -Emu68Settings  
})

$Script:GUIActions.DMAEnabled = $false