$Script:GUIActions.CreateCustomKickstart = $false

$WPF_StartPage_CustomKickstart_CheckBox.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }   
    
    $Script:GUIActions.CreateCustomKickstart = $true
    
})

$WPF_StartPage_CustomKickstart_CheckBox.add_Unchecked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }   
    
    $Script:GUIActions.CreateCustomKickstart = $false

})
