$WPF_StartPage_IconSet_DropDown.Add_SelectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }

    $Script:GUIActions.SelectedIconSet = $WPF_StartPage_IconSet_DropDown.SelectedItem
    
    if (((Get-InputFileCSV -CSV "IconSets") | Where-Object $Script:GUIActions.SelectedIconSet -eq $_.IconSet) -eq $true) {
        $Script:GUIActions.FoundInstallMediatoUse = $null
    }
   
    update-ui -Emu68Settings

})
