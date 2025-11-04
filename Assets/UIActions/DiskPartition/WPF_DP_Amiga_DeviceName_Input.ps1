$WPF_DP_Amiga_DeviceName_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'AlphaNumeric'
    EntryLength = 15
    InputEntry = $null
    InputEntryChanged = $null
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_Amiga_DeviceName_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_Amiga_DeviceName_Input:'
    $WPF_DP_Amiga_DeviceName_Input.InputEntry = $true
})

$WPF_DP_Amiga_DeviceName_Input.add_LostFocus({
    
    if ($WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_DeviceName_Input.Text -and $WPF_DP_Amiga_DeviceName_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_Amiga_DeviceName_Input'
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
            $Script:GUICurrentStatus.SelectedAmigaPartition.DeviceName = $WPF_DP_Amiga_DeviceName_Input.Text
            Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DeviceName_Input -Value 'DeviceName' -CanChangeParameter 'CanRenameDevice'
        }


    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_Amiga_DeviceName_Input'
    }
    $WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed = $null

})
   
$WPF_DP_Amiga_DeviceName_Input.add_TextChanged({
    $WPF_DP_Amiga_DeviceName_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_Amiga_DeviceName_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_DeviceName_Input.Text){
            $WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_DeviceName_Input.Text
            # Write-debug "WPF_DP_Amiga_DeviceName_Input: Recording value of: $($WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_Amiga_DeviceName_Input.EntryType) InputEntry is: $($WPF_DP_Amiga_DeviceName_Input.InputEntry) InputEntryChanged is: $($WPF_DP_Amiga_DeviceName_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_Amiga_DeviceName_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_Amiga_DeviceName_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed)" 
            $WPF_DP_Amiga_DeviceName_Input.InputEntry = $true
            if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                $Script:GUICurrentStatus.SelectedAmigaPartition.DeviceName = $WPF_DP_Amiga_DeviceName_Input.Text
                Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DeviceName_Input -Value 'DeviceName' -CanChangeParameter 'CanRenameDevice'
            }

        }
        else {
            $WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_DeviceName_Input.Text
            # Write-debug "WPF_DP_Amiga_DeviceName_Input: Recording value of: $($WPF_DP_Amiga_DeviceName_Input.ValueWhenEnterorButtonPushed)"
        }
    }
})