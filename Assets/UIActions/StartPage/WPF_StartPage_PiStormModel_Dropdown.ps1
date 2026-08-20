if (Get-Variable -Name 'WPF_StartPage_PiStormModel_Dropdown' -ErrorAction SilentlyContinue) {
    @(
        'PiStorm16',
        'PiStorm32Lite',
        'Classic PiStorm'
    ) | ForEach-Object {
        $WPF_StartPage_PiStormModel_Dropdown.AddChild($_)
    }

    $WPF_StartPage_PiStormModel_Dropdown.SelectedItem = $Script:GUIActions.PiStormModel

    $WPF_StartPage_PiStormModel_Dropdown.Add_SelectionChanged({
        if ($Script:GUICurrentStatus.LoadingSettings) {
            return
        }
        if ($WPF_StartPage_PiStormModel_Dropdown.SelectedItem -and
            $Script:GUIActions.PiStormModel -ne $WPF_StartPage_PiStormModel_Dropdown.SelectedItem) {
            $Script:GUIActions.PiStormModel = $WPF_StartPage_PiStormModel_Dropdown.SelectedItem
            $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
            Update-UI -Emu68Settings
        }
    })
}
