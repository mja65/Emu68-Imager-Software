if (Get-Variable -Name 'WPF_StartPage_NetworkStack_Dropdown' -ErrorAction SilentlyContinue) {
    @(
        'AmiTCP_NG',
        'Roadshow',
        'Miami',
        'AmiNetXDuo',
        'None'
    ) | ForEach-Object {
        $WPF_StartPage_NetworkStack_Dropdown.AddChild($_)
    }

    if (-not $Script:GUIActions.NetworkStack) {
        $Script:GUIActions.NetworkStack = 'AmiTCP_NG'
    }

    $WPF_StartPage_NetworkStack_Dropdown.SelectedItem = $Script:GUIActions.NetworkStack

    $WPF_StartPage_NetworkStack_Dropdown.Add_SelectionChanged({
        if ($Script:GUICurrentStatus.LoadingSettings) {
            return
        }

        $SelectedStack = $WPF_StartPage_NetworkStack_Dropdown.SelectedItem
        if ($SelectedStack -and $Script:GUIActions.NetworkStack -ne $SelectedStack) {
            $Script:GUIActions.NetworkStack = $SelectedStack
            $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
        }
    })
}
