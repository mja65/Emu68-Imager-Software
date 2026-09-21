$WPF_StartPage_PoseidonVersion_RadioButtonRondoval.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        $Script:GUIActions.PoseidonVersion = "6.x" 
        return
    }
       
    $Script:GUIActions.PoseidonVersion = "6.x" 
    
    Get-InputFileCSV -CSV "PoseidonVersions" | ForEach-Object {
        if ($Script:GUIActions.PoseidonVersion -eq $_.PoseidonVersion){
            if ($Script:GUIActions.MUIVersion -notin @($_.MUIVersion -split ',')){
                $Script:GUIActions.MUIVersion = $_.MUIVersionDefault
            }
        }
    }

    Update-UI -Emu68Settings

})
