$WPF_StartPage_OverclockSD_CheckBox.add_Checked({
    $MessageHeader = "SD Card Speed"
    $MessageBody = @"
You have selected the option to change the speed of the SD card. Any value over 50 is an overclock and is not recommended! Only do this if you are sure you know what you are doing! This includes considering the quality and speed rating of your SD card and whether you are using a SD card extender! You may encounter errors. If you are sure you want to do this, press OK otherwise cancel.

"@            

    if (-not ($Script:GUICurrentStatus.LoadingSettings)){

        if ((Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeWarning -ButtonType_OKCancel) -eq "OK"){

            $Script:GUIActions.SDOverClock = $true
            $Script:GUIActions.SDLowSpeed = $false
            $WPF_StartPage_OverclockSD_Slider.Value = 50
            # Triggers the ValueChanged event of the slider which updates the UI and sets the SDOverClockSpeed variable
            #$Script:GUIActions.SDOverClockSpeed = 50
            #$WPF_StartPage_OverclockSD_Value.Text = "50"
            Update-UI -Emu68Settings
    
        }
        else {
            $Script:GUIActions.SDOverClock = $false
            $Script:GUIActions.SDOverClockSpeed = $null
            Update-UI -Emu68Settings
        }
    }
    else {

        $WPF_StartPage_OverclockSD_Slider.Value = $Script:GUIActions.SDOverClockSpeed 
    }

})

$WPF_StartPage_OverclockSD_CheckBox.add_UnChecked({

  $Script:GUIActions.SDOverClock = $false
  Update-UI -Emu68Settings

})

$Script:GUIActions.SDOverClock = $false
