$WPF_StartPage_Unicam_CheckBox.add_Checked({
    $MessageHeader = "Framethrower Enabled"
    if ($WPF_StartPage_ScreenMode_Dropdown.SelectedItem -eq 'Automatic'){
        $MessageBody = @"
You have enabled Unicam settings for Framethrower. Framethrower is still in development and you may need to update Emu68 to the latest version manually in order for it to work properly. Also, if you enable Unicam where you are not actually using it you will notice graphical anomalies when the Amiga switches screenmodes. 

You have also selected automatic screenmode. If you are using Framethrower ideally you should select a specific screenmode (50hz for PAL content).

Please visit the PiStorm discord and the #framethrower-support channel if you need help.
"@        

    }
    else{
        $MessageBody = @"
You have enabled Unicam settings for Framethrower. Framethrower is still in development and you may need to update Emu68 to the latest version manually in order for it to work properly. Also, if you enable Unicam where you are not actually using it you will notice graphical anomalies when the Amiga switches screenmodes. 

Please visit the PiStorm discord and the #framethrower-support channel if you need help.
"@    
    
    }
$null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeWarning -ButtonType_OK
    $WPF_StartPage_Unicam_CheckBox.IsEnabled = 1
    $Script:GUIActions.UnicamEnabled = $true
    $Script:GUIActions.UnicamStartonBoot = $true
    $Script:GUIActions.UnicamScalingType = "Smooth"
    #$Script:GUIActions.UnicamPhase = 64
    $Script:GUIActions.UnicamBParameter = 250
    $Script:GUIActions.UnicamCParameter = 750
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
    #$Script:GUIActions.UnicamPhase = $null
    $Script:GUIActions.UnicamBParameter = $null
    $Script:GUIActions.UnicamCParameter = $null
    $Script:GUIActions.UnicamSizeXPosition = $null
    $Script:GUIActions.UnicamSizeYPosition = $null
    $Script:GUIActions.UnicamOffsetXPosition = $null
    $Script:GUIActions.UnicamOffsetYPosition = $null

    update-ui -Emu68Settings

})