$WPF_Window_Button_PackageSelection.Add_Click({
    if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }

        if (-not ($Script:GUIActions.KickstartVersiontoUse)){
            $null = Show-WarningorError -Msg_Header 'No OS Selected' -Msg_Body 'You cannot select the packages to install or uninstall until you have selected an OS! Please return to this screen after you have selected the OS' -BoxTypeError -ButtonType_OK
            return
        }
    
        if ($Script:GUICurrentStatus.CurrentWindow -ne 'PackageSelection'){

        }

        $Script:GUICurrentStatus.CurrentWindow = 'PackageSelection' 
    
    if ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq "TRUE"){
        Get-SelectablePackages
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "FALSE"
    }
    elseif ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq "KeepInstallPaths"){
        Get-SelectablePackages -KeepInstallStatus
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "FALSE"
    }
      
       
        # if (-not ($Script:WPF_PackageSelection)){
        #     $Script:WPF_PackageSelection = Get-XAML -WPFPrefix 'WPF_PackageSelection_' -XMLFile '.\Assets\WPF\Grid_PackageSelection.xaml' -ActionsPath '.\Assets\UIActions\PackageSelection\' -AddWPFVariables
        # }
    
        for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_Partition.Name){
                $WPF_Window_Main.Children.Remove($WPF_Partition)
            }
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_StartPage.Name){
                $WPF_Window_Main.Children.Remove($WPF_StartPage)
            }
        }
        
        for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
            if ($WPF_Window_Main.Children[$i].Name -eq $WPF_PackageSelection.Name){
                $IsChild = $true
                break
            }
        }

        $Script:GUICurrentStatus.CurrentlySelectedPackage = $null
        $Script:GUICurrentStatus.LastSelectedPackage = $null
        $WPF_PackageSelection_PackageDetails_GroupBox.Visibility = "Hidden"
        Confirm-ValidPackageInstallDrives 
        $WPF_PackageSelection_InstallDrive_Dropdown.Items.Clear()
        
        $WPF_PackageSelection_InstallDrive_Dropdown.AddChild("Workbench")
        if (-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)){
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }      

        Foreach ($Partition in $Script:GUICurrentStatus.AmigaPartitionsandBoundaries){
            If ($Partition.Partition.VolumeName -ne "Workbench"){
                $WPF_PackageSelection_InstallDrive_Dropdown.AddChild($Partition.Partition.VolumeName)
            }
        }

        if ($IsChild -ne $true){
            $WPF_Window_Main.AddChild($WPF_PackageSelection)
        }
        
        Update-AvailablePackagesInScope

        $WPF_PackageSelection_Datagrid_Packages.ItemsSource = $Script:GUIActions.AvailablePackages.DefaultView 
        $WPF_PackageSelection_Datagrid_IconSets.ItemsSource = $Script:GUIActions.AvailableIconSets.DefaultView
        
         if (-not ($WPF_PackageSelection_Datagrid_IconSets.SelectedItem)){
             If ($Script:GUIActions.SelectedIconSet){
                 for ($i = 0; $i -lt $Script:GUIActions.AvailableIconSets.DefaultView.Count; $i++) {
                     if ($Script:GUIActions.SelectedIconSet -eq $Script:GUIActions.AvailableIconSets.DefaultView[$i].IconSet){
                         $RowNumbertoUse = $i
                     }
                 }  
             }
             else {
                 for ($i = 0; $i -lt $Script:GUIActions.AvailableIconSets.DefaultView.Count; $i++) {
                     if ($Script:GUIActions.AvailableIconSets.DefaultView[$i].IconSetDefaultInstall -eq $true){
                         $RowNumbertoUse = $i
                     }
                 }  
             }
    
             $WPF_PackageSelection_Datagrid_IconSets.SelectedItem = $Script:GUIActions.AvailableIconSets.DefaultView[$RowNumbertoUse]
    
         }
        
        $WPF_PackageSelection_Datagrid_Packages.SelectedItem = $null

        update-ui -MainWindowButtons -PackageSelectionWindow

})
