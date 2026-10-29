$WPF_PackageSelection_Datagrid_Packages.add_SelectionChanged({
    $WPF_PackageSelection_PackageDetails_GroupBox.Visibility = "Visible"
    if ($WPF_PackageSelection_Datagrid_Packages.SelectedItems.count -eq 1){
        $WPF_PackageSelection_Title_Label.Visibility = "Visible"
        $WPF_PackageSelection_Title_Value.Visibility = "Visible"
        $WPF_PackageSelection_InstallDrive_Dropdown.IsReadOnly = 0
        $WPF_PackageSelection_InstallPath_Value.IsReadOnly = 0
        $WPF_PackageSelection_InstallDrive_Dropdown.Visibility = "Visible"
        $WPF_PackageSelection_InstallPath_Label.Visibility = "Visible"
        $WPF_PackageSelection_InstallDrive_Label.Visibility = "Visible"
        $WPF_PackageSelection_Description_Label.Visibility = "Visible"
        $WPF_PackageSelection_InstallPath_Value.Visibility = "Visible"
        $WPF_PackageSelection_Author_Value.Visibility = "Visible"
        $WPF_PackageSelection_Author_Label.Visibility = "Visible"
        $WPF_PackageSelection_Link_Label.Visibility = "Visible"
        $WPF_PackageSelection_Link_Value.Visibility = "Visible"
        $Script:GUICurrentStatus.CurrentlySelectedPackage = $WPF_PackageSelection_Datagrid_Packages.SelectedItem
        if (-not ($Script:GUICurrentStatus.LastSelectedPackage)){
            $Script:GUICurrentStatus.LastSelectedPackage = $Script:GUICurrentStatus.CurrentlySelectedPackage
        }
        $WPF_PackageSelection_Title_Value.Text = $Script:GUICurrentStatus.CurrentlySelectedPackage.PackageName 
        If (-not [string]::IsNullOrWhiteSpace($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageAuthor)){
            $WPF_PackageSelection_Author_Value.Text = $Script:GUICurrentStatus.CurrentlySelectedPackage.PackageAuthor
        }
        else {
            $WPF_PackageSelection_Author_Value.Visibility = "Hidden"
            $WPF_PackageSelection_Author_Label.Visibility = "Hidden"
        }
        $WPF_PackageSelection_Link_Value.Inlines.clear()
        If (-not [string]::IsNullOrWhiteSpace($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageURL)){
            $newLink = [System.Windows.Documents.Hyperlink]::new()
            $newLink.NavigateUri = [System.Uri]$Script:GUICurrentStatus.CurrentlySelectedPackage.PackageURL
            $newLink.Inlines.Add($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageURL)
            $newLink.add_RequestNavigate({
                param($sender, $e)
                [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
                    FileName = $e.Uri.AbsoluteUri
                    UseShellExecute = $true
                })
                $e.Handled = $true
            })
    
            $WPF_PackageSelection_Link_Value.Inlines.Add($newLink)
        }
        else {
            $WPF_PackageSelection_Link_Value.Visibility = "Hidden"
            $WPF_PackageSelection_Link_Label.Visibility = "Hidden"
        }
        
        $WPF_PackageSelection_PackageDetails_text.Text = $Script:GUICurrentStatus.CurrentlySelectedPackage.PackageNameDescription
        If ($Script:GUICurrentStatus.CurrentlySelectedPackage.UserDefinableInstallPath -eq $true){
            $WPF_PackageSelection_InstallPath_Value.Text = ($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageUserPath).Replace('\','/')
            If ($Script:GUICurrentStatus.CurrentlySelectedPackage.PackageUserDrive -eq "System"){
                $WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem = "Workbench"
            }
            else {
                $WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem = $Script:GUICurrentStatus.CurrentlySelectedPackage.PackageUserDrive
            }
        }
        else {
            $WPF_PackageSelection_InstallPath_Value.Visibility = "Hidden"
            $WPF_PackageSelection_InstallPath_Label.Visibility = "Hidden"
            $WPF_PackageSelection_InstallDrive_Label.Visibility = "Hidden"
            $WPF_PackageSelection_InstallDrive_Dropdown.Visibility = "Hidden"
            $WPF_PackageSelection_InstallPath_Value.Text = ""   
            $WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem = $null  
            $WPF_PackageSelection_InstallDrive_Dropdown.IsReadOnly = 1
            $WPF_PackageSelection_InstallPath_Value.IsReadOnly = 1
        }
    }
    else {
        if ($WPF_PackageSelection_Datagrid_Packages.SelectedItems.count -eq 0){
            $WPF_PackageSelection_PackageDetails_text.Text = "N/A - No item selected"
            $WPF_PackageSelection_Author_Value.Text = ""
        }
        else {
            $WPF_PackageSelection_PackageDetails_text.Text = "N/A - Multiple items selected"
            $WPF_PackageSelection_Author_Value.Text = ""
        }
        $WPF_PackageSelection_InstallPath_Label.Visibility = "Hidden"
        $WPF_PackageSelection_InstallDrive_Label.Visibility = "Hidden"        
        $WPF_PackageSelection_InstallDrive_Dropdown.SelectedItem = $null  
        $WPF_PackageSelection_InstallDrive_Dropdown.IsReadOnly = 1
        $WPF_PackageSelection_InstallDrive_Dropdown.Visibility = "Hidden"
        $WPF_PackageSelection_Description_Label.Visibility = "Hidden"
        $WPF_PackageSelection_Author_Value.Visibility = "Hidden"
        $WPF_PackageSelection_Author_Label.Visibility = "Hidden"
        $WPF_PackageSelection_Link_Label.Visibility = "Hidden"
        $WPF_PackageSelection_Link_Value.Visibility = "Hidden"
        $WPF_PackageSelection_InstallPath_Value.Visibility = "Hidden"
        $WPF_PackageSelection_InstallPath_Value.IsReadOnly = 1    
        $WPF_PackageSelection_InstallPath_Value.Text = "" 
        $WPF_PackageSelection_Title_Label.Visibility = "Hidden"
        $WPF_PackageSelection_Title_Value.Visibility = "Hidden"          
    }
})
