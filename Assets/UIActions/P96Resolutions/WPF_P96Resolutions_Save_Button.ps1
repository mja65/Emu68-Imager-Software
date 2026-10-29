$WPF_P96Resolutions_Save_Button.Add_Click({
    If ($TargetResolutions){
        $Script:GUIActions.SelectedP96Resolutions = $TargetResolutions.Value
        $WPF_P96ResolutionsWindow.close()
    }
    else {
        $null = Show-WarningorError -Msg_Body "You must save at least one P96 screenmode!" -Msg_Header "No P96 Screenmodes selected" -BoxTypeError -ButtonType_OK
    }

})