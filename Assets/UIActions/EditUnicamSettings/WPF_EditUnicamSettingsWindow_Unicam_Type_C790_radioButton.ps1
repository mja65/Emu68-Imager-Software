$WPF_EditUnicamSettingsWindow_Unicam_Type_C790_radioButton.add_Checked({
    $AllowC790 = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $_.Emu68VersionType -eq $Script:GUIActions.Emu68VersionType })).AllowC790
    If ($AllowC790 -eq $true) {
        $Script:GUIActions.UnicamDeviceType = "c790"
    }
    else {
        $WPF_EditUnicamSettingsWindow_Unicam_Type_FT_radioButton.IsChecked = 1
        $WPF_EditUnicamSettingsWindow_Unicam_Type_C790_radioButton.IsChecked = 0
        return
    }
})