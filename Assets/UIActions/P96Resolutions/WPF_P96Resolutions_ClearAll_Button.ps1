$WPF_P96Resolutions_ClearAll_Button.Add_Click({
    foreach ($item in @($TargetResolutions)) {
        if ($item.display -notmatch '\[SelectedWBMode\]'){
            $TargetResolutions.Remove($item)
            if (-not $item.IsCustom) {
                if (-not $AvailableResolutions.Contains($item.Value)) {
                    $AvailableResolutions.Add($item.Value)
                }
            }
        }
    }
})