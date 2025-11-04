$WPF_DP_Amiga_Buffers_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'Numeric'
    EntryLength = $null
    InputEntry = $null
    InputEntryChanged = $null
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_Amiga_Buffers_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_Amiga_Buffers_Input:'
    $WPF_DP_Amiga_Buffers_Input.InputEntry = $true
})

$WPF_DP_Amiga_Buffers_Input.add_LostFocus({
    
    if ($WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_Buffers_Input.Text -and $WPF_DP_Amiga_Buffers_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_Amiga_Buffers_Input'   
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){{
            $Script:GUICurrentStatus.SelectedAmigaPartition.Buffers = $WPF_DP_Amiga_Buffers_Input.Text
            Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition-TextBoxControl $WPF_DP_Amiga_Buffers_Input -Value 'Buffers' -CanChangeParameter 'CanChangeBuffers'
        }


    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_Amiga_Buffers_Input'
    }
    $WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed = $null

})
   
$WPF_DP_Amiga_Buffers_Input.add_TextChanged({
    $WPF_DP_Amiga_Buffers_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_Amiga_Buffers_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_Buffers_Input.Text){
            $WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_Buffers_Input.Text
            # Write-debug "WPF_DP_Amiga_Buffers_Input: Recording value of: $($WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_Amiga_Buffers_Input.EntryType) InputEntry is: $($WPF_DP_Amiga_Buffers_Input.InputEntry) InputEntryChanged is: $($WPF_DP_Amiga_Buffers_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_Amiga_Buffers_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_Amiga_Buffers_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed)" 
            $WPF_DP_Amiga_Buffers_Input.InputEntry = $true
             if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                 $Script:GUICurrentStatus.SelectedAmigaPartition.Buffers = $WPF_DP_Amiga_Buffers_Input.Text
                 Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Buffers_Input -Value 'Buffers' -CanChangeParameter 'CanChangeBuffers'
             }

        }
        else {
            $WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_Buffers_Input.Text
            # Write-debug "WPF_DP_Amiga_Buffers_Input: Recording value of: $($WPF_DP_Amiga_Buffers_Input.ValueWhenEnterorButtonPushed)"
        }
    }
})

