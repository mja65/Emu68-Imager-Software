$WPF_Window_Button_SaveSettings.Add_Click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }

    Confirm-ValidPackageInstallDrives 
    
    $SavePath = Get-SettingsSavePath
    if ($SavePath){
        $DataToSave = Get-SettingsDataforSave

        if (test-path $SavePath){
            $null = Remove-Item $SavePath
        }
        $DataToSave | Out-File $SavePath
        $null = Show-WarningorError -ButtonType_OK -Msg_Header "Settings Saved" -Msg_Body "The settings have been saved" -BoxTypeNone

    }
})