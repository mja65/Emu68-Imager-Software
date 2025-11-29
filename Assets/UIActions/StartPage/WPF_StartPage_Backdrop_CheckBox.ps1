$Script:GUIActions.WorkbenchBackDropEnabled = $false

$WPF_StartPage_Backdrop_CheckBox.add_Checked({
    $Script:GUIActions.WorkbenchBackDropEnabled = $true
})

$WPF_StartPage_Backdrop_CheckBox.add_UnChecked({
    $Script:GUIActions.WorkbenchBackDropEnabled = $false
})