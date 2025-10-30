$WPF_PackageSelection_ResettoDefault.Add_Click({
    
    if ($Script:GUIActions.DefaultPackagesSelected -ne $true){
        if ((Show-WarningorError -BoxTypeQuestion -Msg_Header "Confirm reset of packages" -Msg_Body "Are you sure you want to reset the packages to the default?" -ButtonType_YesNo) -eq "Yes"){
            if ($Script:GUIActions.FoundInstallMediatoUse){
                $Script:GUIActions.FoundInstallMediatoUse = $null
            }
            $Script:GUIActions.DefaultPackagesSelected = $true
            $Script:GUICurrentStatus.PackagesChanged = $false
        }
        Update-UI -PackageSelectionWindow -Emu68Settings
        Get-SelectablePackages -PackagesOnly
    }

})

