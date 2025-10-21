function Update-GUIInputBox {
    param (
        $InputBox,
        $DropDownBox,
        [Switch]$MBRResize,
        [Switch]$AmigaResize,
        [Switch]$MBRMove_SpaceatBeginning,
        [Switch]$MBRMove_SpaceatEnd,
        [Switch]$AmigaMove_SpaceatBeginning,
        [Switch]$AmigaMove_SpaceatEnd,
        $DiskType        
    )

    # $InputBox = $WPF_DP_SelectedSize_Input
    # $DropDownBox = $WPF_DP_SelectedSize_Input_SizeScale_Dropdown
     

    # InputEntry  User clicked on box
    # InputEntryChanged  User actually changed something
    # InputEntryInvalid  Entry is not valid
    # InputEntryScaleChanged  Scale was changed

    if ($InputBox.InputEntry -eq  $true -and $InputBox.InputEntryChanged -eq $true){
        If (($InputBox.EntryType -eq 'Numeric') -and ((Get-IsValueNumber -TexttoCheck $InputBox.Text) -eq $false)) {
            # Write-debug "InputEntryInvalid:$($InputBox.InputEntryInvalid)"
            $InputBox.InputEntryInvalid = $true #Temp only
            $InputBox.Background = 'Red'
            $InputBox.InputEntry = $false
            $InputBox.InputEntryChanged = $false
            $InputBox.InputEntryInvalid = $false
            $InputBox.InputEntryScaleChanged = $false
            return
        }
        elseif (($InputBox.EntryType -eq 'Hexadecimal') -and ((Confirm-IsHexadecimal -value $InputBox.Text) -eq $false -or $InputBox.Text.Length -ne $InputBox.EntryLength)) {
            # Write-debug "InputEntryInvalid:$($InputBox.InputEntryInvalid)"
            $InputBox.InputEntryInvalid = $true #Temp only
            $InputBox.Background = 'Red'
            $InputBox.InputEntry = $false
            $InputBox.InputEntryChanged = $false
            $InputBox.InputEntryInvalid = $false
            $InputBox.InputEntryScaleChanged = $false
            return
        }
        elseif (($InputBox.EntryType -eq 'AlphaNumeric') -and ((Get-IsValueAlphaNumeric -ValueToTest $InputBox.Text) -eq $false -or $InputBox.Text.Length -ne $InputBox.EntryLength)) {
            # Write-debug "InputEntryInvalid:$($InputBox.InputEntryInvalid)"
            $InputBox.InputEntryInvalid = $true #Temp only
            $InputBox.Background = 'Red'
            $InputBox.InputEntry = $false
            $InputBox.InputEntryChanged = $false
            $InputBox.InputEntryInvalid = $false
            $InputBox.InputEntryScaleChanged = $false
            return
        }
        elseif (($InputBox.EntryType -eq 'Alpha') -and ((Get-IsValueAlpha -ValueToTest $InputBox.Text) -eq $false -or $InputBox.Text.Length -ne $InputBox.EntryLength)) {
            # Write-debug "InputEntryInvalid:$($InputBox.InputEntryInvalid)"
            $InputBox.InputEntryInvalid = $true #Temp only
            $InputBox.Background = 'Red'
            $InputBox.InputEntry = $false
            $InputBox.InputEntryChanged = $false
            $InputBox.InputEntryInvalid = $false
            $InputBox.InputEntryScaleChanged = $false
            return
        }
    }
    
    if ($InputBox.InputEntry -eq  $true -and $InputBox.InputEntryChanged -eq $true){
        if (($MBRResize) -or ($AmigaResize)){                    
            if ($MBRResize){
                # Write-debug 'Changing size based on input - MBR'
                if (-not ($Script:GUICurrentStatus.SelectedGPTMBRPartition)){
                    return
                }
                $ResizeCheck = (Set-GUIPartitionNewSize -ResizeBytes -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition -SizeBytes (Get-ConvertedSize -Size $InputBox.Text -ScaleFrom $DropDownBox.SelectedItem -Scaleto 'B').size -PartitionType 'MBR' -ActiontoPerform 'MBR_ResizeFromRight')
            }
            elseif ($AmigaResize){
                # Write-debug 'Changing size based on input - Amiga'
                  if (-not ($Script:GUICurrentStatus.SelectedAmigaPartition)){
                    return
                }
                $ResizeCheck = (Set-GUIPartitionNewSize -ResizeBytes -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -SizeBytes (Get-ConvertedSize -Size $InputBox.Text -ScaleFrom $DropDownBox.SelectedItem -Scaleto 'B').size -PartitionType 'Amiga' -ActiontoPerform 'Amiga_ResizeFromRight')
            }
            if ($ResizeCheck -eq $false){
                # Write-debug "Invalid Size"
                $InputBox.Background = 'Yellow'
            }
            else{
                $InputBox.Background = 'White'
            }
        }
        if (($MBRMove_SpaceatBeginning) -or ($MBRMove_SpaceatEnd) -or ($AmigaMove_SpaceatBeginning) -or ($AmigaMove_SpaceatEnd)){
            if (($MBRMove_SpaceatBeginning) -or ($MBRMove_SpaceatEnd)){
                $PartitiontoCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | Where-Object {$_.PartitionName -eq $Script:GUICurrentStatus.SelectedGPTMBRPartition}
            }
            elseif (($AmigaMove_SpaceatBeginning) -or ($AmigaMove_SpaceatEnd)){
                $PartitiontoCheck = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -eq $Script:GUICurrentStatus.SelectedAmigaPartition}
            }
            if (($MBRMove_SpaceatBeginning) -or ($AmigaMove_SpaceatBeginning)){
                $AmounttoMove = (Get-ConvertedSize -Size $InputBox.Text -ScaleFrom $DropDownBox.SelectedItem -Scaleto 'B').size-$PartitiontoCheck.BytesAvailableLeft
            }
            elseif (($MBRMove_SpaceatEnd) -or ($AmigaMove_SpaceatEnd)){
                $AmounttoMove = (Get-ConvertedSize -Size $InputBox.Text -ScaleFrom $DropDownBox.SelectedItem -Scaleto 'B').size-$PartitiontoCheck.BytesAvailableRight
                
            }
            # Write-debug 'Moving partition based on input'
            # Write-debug "Amount to Move is: $AmounttoMove"
            if (($AmounttoMove -gt 0 -and $AmounttoMove -gt $PartitiontoCheck.BytesAvailableRight) -or ($AmounttoMove -lt 0 -and ($AmounttoMove*-1) -gt $PartitiontoCheck.BytesAvailableLeft)){
                # Write-debug "Space available right is: $($PartitiontoCheck.BytesAvailableRight)"
                # Write-debug "Space available left is: $($PartitiontoCheck.BytesAvailableLeft)"
                # Write-debug "Invalid Size"
                $InputBox.Background = 'Yellow'
            }
            else {
                $InputBox.Background = 'White'
                if (($MBRMove_SpaceatBeginning) -or ($MBRMove_SpaceatEnd)){
                    Set-GUIPartitionNewPosition -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition -AmountMovedBytes $AmounttoMove -PartitionType 'MBR'                    
                } 
                elseif (($AmigaMove_SpaceatBeginning) -or ($AmigaMove_SpaceatEnd)){
                    Set-GUIPartitionNewPosition -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -AmountMovedBytes $AmounttoMove -PartitionType 'Amiga'                         
                }


                
            }                                  
        }

        $InputBox.InputEntry = $false
        $InputBox.InputEntryChanged = $false
        $InputBox.InputEntryInvalid = $false
        $InputBox.InputEntryScaleChanged = $false

    }
}

# $ValueTotest = '0xffffff'
# $ValuetoTest = '0x7ffffffe'

# Confirm-IsHexadecimal -value $ValuetoTest 

