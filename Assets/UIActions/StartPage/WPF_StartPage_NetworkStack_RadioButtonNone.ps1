$WPF_StartPage_NetworkStack_RadioButtonNone.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }
    if ($Script:GUIActions.NetworkStack -ne "None"){
        $Msg_Header = "No TCP/IP Stack"
        $Msg_Body =  "You have selected that no TCP/IP stack will be installed. This means you will not be able to go online unless you manually install software such as Roadshow, Miami or AmiNetXDuo and manually set up commands to go online and offline. Are you sure you want to do this?"
        $Response = Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -ButtonType_YesNo -BoxTypeWarning
        If ($Response -eq "Yes"){
            $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
            $Script:GUIActions.NetworkStack = "None"
            $WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 0
            $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
            $WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 0
        }
        else {
            If ($Script:GUIActions.NetworkStack -eq "Roadshow"){
                $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 1
            } 
            elseif ($Script:GUIActions.NetworkStack -eq "Miami"){
                $WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 1
            }
            elseif ($Script:GUIActions.NetworkStack -eq "AmiNetXDuo"){
                $WPF_StartPage_NetworkStack_RadioButtonNone.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonRoadshow.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonMiami.IsChecked = 0
                $WPF_StartPage_NetworkStack_RadioButtonAmiNetXDuo.IsChecked = 1
            }
        }
    }
})
