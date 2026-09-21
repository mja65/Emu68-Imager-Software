
$WPF_StartPage_NetworkStack_Dropdown.Add_SelectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }

    Get-InputFileCSV -CSV "NetworkStackVersions" | ForEach-Object {
        if ($WPF_StartPage_NetworkStack_Dropdown.SelectedItem -eq $_.NetworkStackFriendlyName){
            $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "KeepInstallPaths"
            $Script:GUIActions.NetworkStack = $_.NetworkStack
        }
    }
    
    update-ui -Emu68Settings
    
})

    