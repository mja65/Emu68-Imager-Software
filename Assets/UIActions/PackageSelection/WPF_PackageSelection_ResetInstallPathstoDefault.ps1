$WPF_PackageSelection_ResetInstallPathstoDefault.Add_Click({
    $NoChangedInstallPaths = Confirm-NoChangedInstallPaths
    If ($NoChangedInstallPaths -eq $false){
        if ((Show-WarningorError -BoxTypeQuestion -Msg_Header "Confirm reset of install paths" -Msg_Body "Are you sure you want to reset the install paths of the packages to the default?" -ButtonType_YesNo) -eq "Yes") {

            $Script:GUIActions.AvailablePackages.ForEach({
                $_.PackageUserDrive = $_.PackageDefaultDrive 
                $_.PackageUserPath = $_.PackageDefaultPath
            })
            
            $WPF_PackageSelection_Datagrid_Packages.SelectedItem = $null

        }
            
    }
})