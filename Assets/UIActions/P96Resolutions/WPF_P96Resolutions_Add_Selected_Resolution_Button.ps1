$WPF_P96Resolutions_Add_Selected_Resolution_Button.Add_Click({
    $items = @($WPF_P96Resolutions_AvailableResolutionsList.SelectedItems)
    foreach ($item in $items) {
        $AvailableResolutions.Remove($item)
        if (-not ($TargetResolutions | Where-Object { $_.Value -eq $item })) {
            $TargetResolutions.Add([PSCustomObject]@{
                Value    = $item.value
                IsCustom = $false
                Display  = $item.Display
            })
        }
    }
})

