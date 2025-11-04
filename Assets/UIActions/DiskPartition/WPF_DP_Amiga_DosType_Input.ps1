$WPF_DP_Amiga_DosType_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'AlphaNumericDosType'
    EntryLength = 11
    InputEntry = $null
    InputEntryChanged = $null
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_Amiga_DosType_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_Amiga_DosType_Input:'
    $WPF_DP_Amiga_DosType_Input.InputEntry = $true
})

$WPF_DP_Amiga_DosType_Input.add_LostFocus({
    
    if ($WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_DosType_Input.Text -and $WPF_DP_Amiga_DosType_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_Amiga_DosType_Input'
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
            $Script:GUICurrentStatus.SelectedAmigaPartition.DosType = $WPF_DP_Amiga_DosType_Input.Text
            Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DosType_Input -Value 'DosType' -CanChangeParameter 'CanChangeDosType'
        }


    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_Amiga_DosType_Input'
    }
    $WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed = $null

})
   
$WPF_DP_Amiga_DosType_Input.add_TextChanged({
    $WPF_DP_Amiga_DosType_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_Amiga_DosType_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_DosType_Input.Text){
            $WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_DosType_Input.Text
            # Write-debug "WPF_DP_Amiga_DosType_Input: Recording value of: $($WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_Amiga_DosType_Input.EntryType) InputEntry is: $($WPF_DP_Amiga_DosType_Input.InputEntry) InputEntryChanged is: $($WPF_DP_Amiga_DosType_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_Amiga_DosType_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_Amiga_DosType_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed)" 
            $WPF_DP_Amiga_DosType_Input.InputEntry = $true
             if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                 $Script:GUICurrentStatus.SelectedAmigaPartition.DosType = $WPF_DP_Amiga_DosType_Input.Text
                 Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DosType_Input -Value 'DosType' -CanChangeParameter 'CanChangeDosType'
             }

        }
        else {
            $WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_DosType_Input.Text
            # Write-debug "WPF_DP_Amiga_DosType_Input: Recording value of: $($WPF_DP_Amiga_DosType_Input.ValueWhenEnterorButtonPushed)"
        }
    }
})