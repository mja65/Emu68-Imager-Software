$WPF_DP_Disk_Type_DropDown.Items.Clear()

Get-InputFileCSV -CSV "DiskTypes" | ForEach-Object {
    $WPF_DP_Disk_Type_DropDown.AddChild($_.DiskTypeFriendlyName)
    if ($_.Default -eq $true){
        $Script:GUIActions.DiskType = $_.DiskType
    }
        
}

$WPF_DP_Disk_Type_DropDown.add_selectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }    
})