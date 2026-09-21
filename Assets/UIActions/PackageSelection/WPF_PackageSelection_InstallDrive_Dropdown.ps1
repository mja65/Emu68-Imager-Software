$WPF_PackageSelection_InstallDrive_Dropdown.add_SelectionChanged({
    if ($Script:GUICurrentStatus.CurrentlySelectedPackage.UserDefinableInstallPath -eq $true){
        $WPF_PackageSelection_Datagrid_Packages.Items | ForEach-Object {
            if ($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageName -eq $_.PackageName){
                if ($WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem -eq "Workbench") {
                   $_.PackageUserDrive = "System" 
                }
                else {
                    $_.PackageUserDrive = $WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem 
                }
                    
            }
        }
    }
})
