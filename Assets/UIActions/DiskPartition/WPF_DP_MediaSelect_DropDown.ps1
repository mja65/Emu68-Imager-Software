if (-not $Script:GUIActions.ListofRemovableMedia){
    $Script:GUIActions.ListofRemovableMedia = Get-RemovableMedia
    #$WPF_DP_MediaSelect_DropDown.ItemsSource = ($Script:GUIActions.ListofRemovableMedia)
    $WPF_DP_MediaSelect_Dropdown.Items.Clear()
    foreach ($Disk in $Script:GUIActions.ListofRemovableMedia){
        $WPF_DP_MediaSelect_DropDown.AddChild($Disk.FriendlyName)       
    }
}
$WPF_DP_MediaSelect_DropDown.add_selectionChanged({
    if ($WPF_DP_MediaSelect_DropDown.SelectedItem){
        $Script:GUIActions.ListofRemovableMedia | ForEach-Object{
            if ($WPF_DP_MediaSelect_DropDown.SelectedItem -eq $_.FriendlyName){
                $Script:GUIActions.OutputPath = $_.HSTDiskName
                if ($Script:GUIActions.DiskSizeSelected -eq $true){
                    Set-RevisedDiskValues -SizeBytes ($_.SizeofDisk*1024)
                }
                else {
                    Set-InitialDiskValues -SizeBytes ($_.SizeofDisk*1024) -DiskType $WPF_DP_Disk_Type_DropDown.SelectedItem
                }
            }
        }
        update-ui -DiskPartitionWindow
    }
})

