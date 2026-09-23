$WPF_StartPage_ForceAgnus_CheckBox.add_Checked({
    If (-not ($Script:GUICurrentStatus.LoadingSettings)){
        $Script:GUIActions.AgnusType = "PAL"
        Update-UI -Emu68Settings
    }
})

$WPF_StartPage_ForceAgnus_CheckBox.add_UnChecked({
    If (-not ($Script:GUICurrentStatus.LoadingSettings)){
        $Script:GUIActions.AgnusType = $null
        Update-UI -Emu68Settings
    }
})

