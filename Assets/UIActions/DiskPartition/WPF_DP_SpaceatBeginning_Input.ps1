$WPF_DP_SpaceatBeginning_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'Numeric'
    EntryLength = $null
    InputEntry = $false # User clicked on box
    InputEntryChanged = $false # User actually changed something
    InputEntryInvalid = $false # Entry is not valid
    InputEntryScaleChanged = $false # Scale was changed
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_SpaceatBeginning_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_SpaceatBeginning_Input:'
    $WPF_DP_SpaceatBeginning_Input.InputEntry = $true
    $Script:GUICurrentStatus.TextBoxEntryFocus = 'WPF_DP_SpaceatBeginning_Input'

})

$WPF_DP_SpaceatBeginning_Input.add_LostFocus({
    
    if ($WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_SpaceatBeginning_Input.Text -and $WPF_DP_SpaceatBeginning_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_SpaceatBeginning_Input'
        Update-GUIInputBox -InputBox $WPF_DP_SpaceatBeginning_Input -DropDownBox $WPF_DP_SpaceatBeginning_Input_SizeScale_Dropdown -MBRMove_SpaceatBeginning
    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_SpaceatBeginning_Input'
    }
    
    update-ui -UpdateInputBoxes
    $WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed = $null
    $Script:GUICurrentStatus.TextBoxEntryFocus = $null 

})
   
$WPF_DP_SpaceatBeginning_Input.add_TextChanged({
    $WPF_DP_SpaceatBeginning_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_SpaceatBeginning_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_SpaceatBeginning_Input.Text){
            $WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed = $WPF_DP_SpaceatBeginning_Input.Text
            # Write-debug "WPF_DP_SpaceatBeginning_Input: Recording value of: $($WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_SpaceatBeginning_Input.EntryType) InputEntry is: $($WPF_DP_SpaceatBeginning_Input.InputEntry) InputEntryChanged is: $($WPF_DP_SpaceatBeginning_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_SpaceatBeginning_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_SpaceatBeginning_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed)" 

            $WPF_DP_SpaceatBeginning_Input.InputEntry = $true
            Update-GUIInputBox -InputBox $WPF_DP_SpaceatBeginning_Input -DropDownBox $WPF_DP_SpaceatBeginning_Input_SizeScale_Dropdown -MBRMove_SpaceatBeginning
            update-ui -UpdateInputBoxes
            
        }
        else {
            $WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed = $WPF_DP_SpaceatBeginning_Input.Text
            # Write-debug "WPF_DP_SpaceatBeginning_Input: Recording value of: $($WPF_DP_SpaceatBeginning_Input.ValueWhenEnterorButtonPushed)"

        }
    }
})
