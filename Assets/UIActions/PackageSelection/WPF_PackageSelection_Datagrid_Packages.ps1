$WPF_PackageSelection_Datagrid_Packages.add_PreparingCellForEdit({
        if ($Script:GUICurrentStatus.PackagesChanged -ne $true){
            $Script:GUICurrentStatus.PackagesChanged = $true
            $Script:GUIActions.DefaultPackagesSelected = $false

            if ($Script:GUIActions.FoundInstallMediatoUse){
                $WPF_PackageSelection_PackageSelection_Label.Text = "You have made changes to the packages and/or icons. You will need to reperform the check for install media."

            }

            $Script:GUIActions.FoundInstallMediatoUse = $null
            Update-UI -PackageSelectionWindow -Emu68Settings
        } 
})