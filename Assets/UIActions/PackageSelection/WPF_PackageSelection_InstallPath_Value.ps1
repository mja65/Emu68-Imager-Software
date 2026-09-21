$WPF_PackageSelection_InstallPath_Value | Add-Member -NotePropertyMembers @{
    EntryType = 'AlphaNumeric'
    EntryLength = 107
    InputEntry = $false # User clicked on box
    InputEntryChanged = $false # User actually changed something
    InputEntryInvalid = $false # Entry is not valid
    ValueWhenEnterorButtonPushed = $null
}

$WPF_PackageSelection_InstallPath_Value.add_gotFocus({
    $Script:GUICurrentStatus.LastSelectedPackage = $Script:GUICurrentStatus.CurrentlySelectedPackage 
    $WPF_PackageSelection_InstallPath_Value.InputEntry = $true
    $Script:GUICurrentStatus.TextBoxEntryFocus = 'WPF_PackageSelection_InstallPath_Value'        
    $WPF_PackageSelection_Datagrid_Packages.IsReadOnly = 1
    $WPF_PackageSelection_Datagrid_Packages.IsHitTestVisible = 1    
})

$WPF_PackageSelection_InstallPath_Value.add_lostFocus({
    $RevisedInstallPath = Get-AmigaFilePath -InputFilePath $WPF_PackageSelection_InstallPath_Value.Text
    If ($RevisedInstallPath){
        if ($Script:GUICurrentStatus.LastSelectedPackage){
            $WPF_PackageSelection_Datagrid_Packages.Items | ForEach-Object {
                if ($Script:GUICurrentStatus.LastSelectedPackage.PackageName -eq $_.PackageName){
                    $_.PackageUserPath = $RevisedInstallPath
                }
            }
    
        }
    }
    $WPF_PackageSelection_Datagrid_Packages.IsReadOnly = 0
    $WPF_PackageSelection_Datagrid_Packages.IsHitTestVisible = 1
    Get-AmigaFilePath -InputFilePath $WPF_PackageSelection_InstallPath_Value.Text = $RevisedInstallPath
})
