# $AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.csv') -delimiter ';' | Where-Object 'Include' -eq 'TRUE'

$Script:GUIActions.AvailableScreenModes = (Get-InputFileCSV -CSV 'ScreenModes')

foreach ($ScreenMode in $Script:GUIActions.AvailableScreenModes) {
    $WPF_StartPage_ScreenMode_Dropdown.AddChild($ScreenMode.FriendlyName)
}

if ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
    $WPF_StartPage_ScreenMode_Dropdown.AddChild("Custom ScreenMode")
}

$Script:GUIActions.ScreenModetoUseFriendlyName = 'Automatic'
$WPF_StartPage_ScreenMode_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseFriendlyName 
$Script:GUIActions.ScreenModetoUse = 'Auto'

$WPF_StartPage_ScreenMode_Dropdown.Add_SelectionChanged({
    if ($WPF_StartPage_ScreenMode_Dropdown.SelectedItem -eq "Custom ScreenMode"){
        if ($Script:GUIActions.ScreenModetoUse -ne "Custom"){
            $null = Show-WarningorError -Msg_Header "Setting Custom Screen Mode" -Msg_Body "You are setting a custom screenmode! Pay attention to the values you select as you could select an invalid screenmode resulting in no display! If you do not know what you are doing, do not use a custom screenmode!" -BoxTypeWarning -ButtonType_OK
            $Script:GUIActions.CustomScreenMode_Height = $null
            $Script:GUIActions.CustomScreenMode_Width = $null
            $Script:GUIActions.CustomScreenMode_Aspect = "16:9"
            $Script:GUIActions.CustomScreenMode_Margins = "Disabled"
            $Script:GUIActions.CustomScreenMode_Interlace = "Progressive"
            $Script:GUIActions.CustomScreenMode_RB = "Normal"
        }

        $Script:GUIActions.ScreenModetoUse = "Custom"
        $Script:GUIActions.ScreenModetoUseFriendlyName = "Custom ScreenMode"
        
    }
          
    else {
        $PIScreenModeDetails = ($Script:GUIActions.AvailableScreenModes | Where-Object {$_.FriendlyName -eq $WPF_StartPage_ScreenMode_Dropdown.SelectedItem})
        $Script:GUIActions.ScreenModetoUse = $PIScreenModeDetails.Name
        $Script:GUIActions.ScreenModetoUseFriendlyName = $PIScreenModeDetails.FriendlyName
    }
       
    $null = Update-UI -Emu68Settings -WBScreenModeUpdate

})