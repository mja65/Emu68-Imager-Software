$WPF_StartPage_DisableSCSI_CheckBox.add_Checked({
    $Script:GUIActions.SCSIDeviceDisabled = $true
    Update-UI -Emu68Settings
})

$WPF_StartPage_DisableSCSI_CheckBox.add_UnChecked({
    $Script:GUIActions.SCSIDeviceDisabled = $false
    Update-UI -Emu68Settings    
})
