$WPF_DP_Amiga_Priority_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'Numeric'
    EntryLength = $null
    InputEntry = $null
    InputEntryChanged = $null
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_Amiga_Priority_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_Amiga_Priority_Input:'
    $WPF_DP_Amiga_Priority_Input.InputEntry = $true
})

$WPF_DP_Amiga_Priority_Input.add_LostFocus({
    
    if ($WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_Priority_Input.Text -and $WPF_DP_Amiga_Priority_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_Amiga_Priority_Input'
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
            $Script:GUICurrentStatus.SelectedAmigaPartition.Priority = $WPF_DP_Amiga_Priority_Input.Text
            Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Priority_Input -Value 'Priority' -CanChangeParameter 'CanChangePriority'
        }

    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_Amiga_Priority_Input'
    }
    $WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed = $null

})
   
$WPF_DP_Amiga_Priority_Input.add_TextChanged({
    $WPF_DP_Amiga_Priority_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_Amiga_Priority_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_Priority_Input.Text){
            $WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_Priority_Input.Text
            # Write-debug "WPF_DP_Amiga_Priority_Input: Recording value of: $($WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_Amiga_Priority_Input.EntryType) InputEntry is: $($WPF_DP_Amiga_Priority_Input.InputEntry) InputEntryChanged is: $($WPF_DP_Amiga_Priority_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_Amiga_Priority_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_Amiga_Priority_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed)" 

            $WPF_DP_Amiga_Priority_Input.InputEntry = $true
            if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                $Script:GUICurrentStatus.SelectedAmigaPartition.Priority = $WPF_DP_Amiga_Priority_Input.Text
                Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Priority_Input -Value 'Priority' -CanChangeParameter 'CanChangePriority'
            }

        }
        else {
            $WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_Priority_Input.Text
            # Write-debug "WPF_DP_Amiga_Priority_Input: Recording value of: $($WPF_DP_Amiga_Priority_Input.ValueWhenEnterorButtonPushed)"

        }
    }
})