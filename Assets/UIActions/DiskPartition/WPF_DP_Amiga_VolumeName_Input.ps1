$WPF_DP_Amiga_VolumeName_Input | Add-Member -NotePropertyMembers @{
    EntryType = 'AlphaNumeric'
    EntryLength = 15
    InputEntry = $null
    InputEntryChanged = $null
    ValueWhenEnterorButtonPushed = $null
}

$WPF_DP_Amiga_VolumeName_Input.add_GotFocus({
    # Write-debug 'Got Focus - WPF_DP_Amiga_VolumeName_Input:'
    $WPF_DP_Amiga_VolumeName_Input.InputEntry = $true
    $WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed = $Script:GUICurrentStatus.SelectedAmigaPartition.volumeName 
})

$WPF_DP_Amiga_VolumeName_Input.add_LostFocus({
    
    if ($WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_VolumeName_Input.Text -and $WPF_DP_Amiga_VolumeName_Input.InputEntryChanged){
        # Write-debug 'Lost Focus - Performing action for WPF_DP_Amiga_VolumeName_Input' 
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
            $Script:GUICurrentStatus.SelectedAmigaPartition.volumeName = $WPF_DP_Amiga_VolumeName_Input.Text
            Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_VolumeName_Input -Value 'VolumeName' -CanChangeParameter 'CanRenameVolume'
        }   
        
    }
    else {
        # Write-debug 'Lost Focus - Not performing action for WPF_DP_Amiga_VolumeName_Input'
    }
    $WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed = $null

})
   
$WPF_DP_Amiga_VolumeName_Input.add_TextChanged({
    $WPF_DP_Amiga_VolumeName_Input.InputEntryChanged = $true
    # Write-debug 'Text Changed'
})

$WPF_DP_Amiga_VolumeName_Input.Add_KeyDown({
    if ($_.Key -eq 'Return'){       
        # Write-debug "Key pressed was: $($_.Key)"
        if ($WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed -ne $WPF_DP_Amiga_VolumeName_Input.Text){
            $WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_VolumeName_Input.Text
            # Write-debug "WPF_DP_Amiga_VolumeName_Input: Recording value of: $($WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed) and actioning. EntryType is: $($WPF_DP_Amiga_VolumeName_Input.EntryType) InputEntry is: $($WPF_DP_Amiga_VolumeName_Input.InputEntry) InputEntryChanged is: $($WPF_DP_Amiga_VolumeName_Input.InputEntryChanged) InputEntryInvalid is: $($WPF_DP_Amiga_VolumeName_Input.InputEntryInvalid) InputEntryScaleChanged is: $($WPF_DP_Amiga_VolumeName_Input.InputEntryScaleChanged) ValueWhenEnterorButtonPushed is: $($WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed)" 

            $WPF_DP_Amiga_VolumeName_Input.InputEntry = $true
            if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                $Script:GUICurrentStatus.SelectedAmigaPartition.volumeName = $WPF_DP_Amiga_VolumeName_Input.Text
                Update-UITextbox -Partition $script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_VolumeName_Input -Value 'VolumeName' -CanChangeParameter 'CanRenameVolume'
            }

        }
        else {
            $WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed = $WPF_DP_Amiga_VolumeName_Input.Text
            # Write-debug "WPF_DP_Amiga_VolumeName_Input: Recording value of: $($WPF_DP_Amiga_VolumeName_Input.ValueWhenEnterorButtonPushed)"

        }
    }
})