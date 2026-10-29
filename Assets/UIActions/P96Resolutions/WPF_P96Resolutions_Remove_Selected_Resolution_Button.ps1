$WPF_P96Resolutions_Remove_Selected_Resolution_Button.Add_Click({
    $items = @($WPF_P96Resolutions_IncludedResolutionsList.SelectedItems)
    If ($WPF_P96Resolutions_IncludedResolutionsList.SelectedItems.Display -match '\[SelectedWBMode\]'){
        $MessageHeader = "Cannot remove Screenmode"
        $MessageBody = "You have selected the screenmode you have set workbench to use! Cannot remove."
        $null = Show-WarningorError -Msg_Body $MessageBody -Msg_Header $MessageHeader -BoxTypeError -ButtonType_OK
        return
    } 
    foreach ($item in $items) {
        $TargetResolutions.Remove($item)
        if (-not $item.IsCustom) {
            if (-not $AvailableResolutions.Contains($item.Value)) {
                $AvailableResolutions.Add($item)
            }
        }
    }
})

