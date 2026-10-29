$WPF_StartPage_DeleteFiles_CheckBox.add_Checked({
    $Script:GUIActions.DeleteAllDownloadedFiles = $true
}) 

$WPF_StartPage_DeleteFiles_CheckBox.add_UnChecked({
    $Script:GUIActions.DeleteAllDownloadedFiles = $false   
}) 

$Script:GUIActions.DeleteAllDownloadedFiles = $false