$WPF_StartPage_EnableBupTest_CheckBox.add_Checked({
    if (((Get-InputFileCSV -CSV "Emu68Versions").where({ $Script:GUIActions.Emu68VersionType -eq $_.Emu68VersionType  })).EnableBupTest -eq $false){
        $WPF_StartPage_EnableBupTest_CheckBox.IsChecked = 0
        return
    }
    $Script:GUIActions.EnableBupTest = $true
    Update-UI -Emu68Settings
})

$WPF_StartPage_EnableBupTest_CheckBox.add_UnChecked({
    $Script:GUIActions.EnableBupTest = $false  
    Update-UI -Emu68Settings  
})

If ($Script:GUIActions.Emu68VersionType){
    $Script:GUIActions.EnableBupTest = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $Script:GUIActions.Emu68VersionType -eq $_.Emu68VersionType  })).EnableBupTest
}
else {
    $Em68Version = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $_.Default -eq $true })).Emu68VersionType
    $Script:GUIActions.EnableBupTest = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $Em68Version -eq $_.Emu68VersionType  })).EnableBupTest
}
