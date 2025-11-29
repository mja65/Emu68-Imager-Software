$WPF_StartPage_Unicam_CheckBox.add_Checked({
    if ($WPF_StartPage_ScreenMode_Dropdown.SelectedItem -eq 'Automatic'){
        $MessageHeader = "Non Optimum ScreenMode"
        $MessageBody = "You have automatic screenmode selected. If you are using Framethrower you should select a specific screenmode (ideally 50hz for PAL content)"
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeWarning -ButtonType_OK
    }
    $WPF_StartPage_Unicam_CheckBox.IsEnabled = 1
    $Script:GUIActions.UnicamEnabled = $true
    $Script:GUIActions.UnicamStartonBoot = [bool]$null
    $Script:GUIActions.UnicamScalingType = "Smooth"
    $Script:GUIActions.UnicamBParameter = 20
    $Script:GUIActions.UnicamCParameter = 0
    $Script:GUIActions.UnicamSizeXPosition = $null
    $Script:GUIActions.UnicamSizeYPosition = $null
    $Script:GUIActions.UnicamOffsetXPosition = $null
    $Script:GUIActions.UnicamOffsetYPosition = $null

    update-ui -Emu68Settings

})

$WPF_StartPage_Unicam_CheckBox.add_UnChecked({
    $WPF_StartPage_Unicam_CheckBox.IsEnabled = 0
    $Script:GUIActions.UnicamEnabled = $false
    $Script:GUIActions.UnicamStartonBoot = [bool]$null
    $Script:GUIActions.UnicamScalingType = $null
    $Script:GUIActions.UnicamBParameter = $null
    $Script:GUIActions.UnicamCParameter = $null
    $Script:GUIActions.UnicamSizeXPosition = $null
    $Script:GUIActions.UnicamSizeYPosition = $null
    $Script:GUIActions.UnicamOffsetXPosition = $null
    $Script:GUIActions.UnicamOffsetYPosition = $null

    update-ui -Emu68Settings

})