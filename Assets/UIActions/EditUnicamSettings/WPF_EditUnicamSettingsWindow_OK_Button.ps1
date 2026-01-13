$WPF_EditUnicamSettingsWindow_OK_Button.Add_Click({
    # if (-not ($WPF_NewPartitionWindow_Input_PartitionSize_Value.Text)){
    #     $WPF_NewPartitionWindow_ErrorMessage_Label.Text = "No value entered!"
    #     return
    # }
    # if ((Get-IsValueNumber -TexttoCheck $WPF_NewPartitionWindow_Input_PartitionSize_Value.Text) -eq $false){
    #     $WPF_NewPartitionWindow_ErrorMessage_Label.Text = "Size of partition must be a number!"
    #     return
    # }
    # if  ((Get-IsValueNumber -TexttoCheck $WPF_NewPartitionWindow_Input_PartitionSize_Value.Text) -eq $true){
    #     $WPF_NewPartitionWindow_ErrorMessage_Label.Text = ""
    #     $ValuetoCheck = (Get-ConvertedSize -Size $WPF_NewPartitionWindow_Input_PartitionSize_Value.Text -ScaleFrom $WPF_NewPartitionWindow_Input_PartitionSize_SizeScale_Dropdown.Text -Scaleto 'B').size 
    #     # Write-debug "Textbox is: $($WPF_NewPartitionWindow_Input_PartitionSize_Value.Text) Value input is: $ValuetoCheck Maximum allowed size is: $($Script:GUICurrentStatus.NewPartitionMaximumSizeBytes)"  
    #     if (-not (($ValuetoCheck -le $Script:GUICurrentStatus.NewPartitionMaximumSizeBytes) -and $ValuetoCheck -ge ($Script:GUICurrentStatus.NewPartitionMinimumSizeBytes))){
    #         $WPF_NewPartitionWindow_ErrorMessage_Label.Text = "Size of partition must be less than maximum size and greater than the minimum size!"
    #         return
    #     }
    #     else {
    #         $Script:GUICurrentStatus.NewPartitionAcceptedNewValue = $true
    
    if ($WPF_EditUnicamSettingsWindow_Unicam_StartBoot_checkBox.IsChecked -eq $true){
        $Script:GUIActions.UnicamStartonBoot = $true
    }
    else {
    $Script:GUIActions.UnicamStartonBoot = $false
    }
    
    if ($WPF_EditUnicamSettingsWindow_Unicam_IntegerScaling_radioButton.IsChecked -eq $true){
        $Script:GUIActions.UnicamScalingType = "Integer"
    }
    elseif ($WPF_EditUnicamSettingsWindow_Unicam_SmoothScaling_radioButton.IsChecked -eq $true){
        $Script:GUIActions.UnicamScalingType = "Smooth"
    }
       
    #$Script:GUIActions.UnicamPhase = $WPF_EditUnicamSettingsWindow_Phase_Input.Text
    $Script:GUIActions.UnicamBParameter = $WPF_EditUnicamSettingsWindow_B_Parameter_Input.Text
    $Script:GUIActions.UnicamCParameter = $WPF_EditUnicamSettingsWindow_C_Parameter_Input.Text
    $Script:GUIActions.UnicamSizeXPosition = $WPF_EditUnicamSettingsWindow_Size_X_Input.Text
    $Script:GUIActions.UnicamSizeYPosition = $WPF_EditUnicamSettingsWindow_Size_Y_Input.Text
    $Script:GUIActions.UnicamOffsetXPosition = $WPF_EditUnicamSettingsWindow_offset_X_Input.Text
    $Script:GUIActions.UnicamOffsetYPosition = $WPF_EditUnicamSettingsWindow_offset_Y_Input.Text

    $null = $WPF_EditUnicamSettingsWindow.Close()
    
    #     }
    # }

})