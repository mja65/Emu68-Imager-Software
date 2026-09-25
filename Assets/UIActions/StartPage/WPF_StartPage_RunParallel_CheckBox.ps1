$WPF_StartPage_RunParallel_CheckBox.add_Checked({
    $Script:GUIActions.RunParallel = $true
}) 

$WPF_StartPage_RunParallel_CheckBox.add_UnChecked({
    $Script:GUIActions.RunParallel = $false   
}) 


If ($Script:GUICurrentStatus.RunParallelInstalled -eq "Yes"){
    $Script:GUIActions.RunParallel = $true
}
else {
    $Script:GUIActions.RunParallel = $false  
}
