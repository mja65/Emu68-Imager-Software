$WPF_StartPage_MUIVersion_38.add_Checked({
    Get-InputFileCSV -CSV "MUIVersions" | ForEach-Object {
        If ($_.MUIVersion -eq "3.8"){
            if ($Script:GUIActions.Emu68VersionType -notin @($_.Emu68VersionType -split ',')){
                $MessageHeader = "Poseidon - AROS Backport"
                $MessageBody = "You have selected the AROS backported edition of Poseidon which requires MUI 5.0."
                Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK 
                $Script:GUIActions.MUIVersion = "5.0"
                $WPF_StartPage_MUIVersion_50.IsChecked = 1
                return                                
            }
        }
    }

    $Script:GUIActions.MUIVersion = "3.8"    
      
})

Get-InputFileCSV -CSV "MUIVersions" | ForEach-Object {
    if ($_.Default -eq $true){
        $Script:GUIActions.MUIVersion = $_.MUIVersion
    }
}
