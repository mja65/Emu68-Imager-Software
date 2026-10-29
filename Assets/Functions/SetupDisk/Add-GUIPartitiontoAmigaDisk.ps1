function Add-GUIPartitiontoAmigaDisk {
    param (
        [Switch]$LoadSettings,
        $NewPartitionNameFromSettings,
        [switch]$DefaultPartition,
        $AmigaDiskName,
        $AddType,
        $PartitionNameNextto, 
        $SizeBytes,
        $PartitionTypeAmiga,
        $ImportedFilesPath,
        $ImportedFilesSpaceBytes,
        $DeviceName,
        $VolumeName,
        $Buffers,
        $DosType,
        $MaxTransfer,
        $Bootable,
        $NoMount,
        $Priority,
        $Mask
    )
    
    # $AmigaDiskName = 'WPF_DP_Partition_MBR_2_AmigaDisk'
    # $WPF_DP_Partition_ID76_1_AmigaDisk_Partition_1
    # $PartitionNameNextto = 'WPF_DP_Partition_ID76_1_AmigaDisk_Partition_1'
    # $AddType = 'AtEnd'
   
    # Write-Debug "Function: $($MyInvocation.MyCommand.Name)"
    # Write-Debug "Parameters received: $($PSBoundParameters | Out-String)"

    $SizePixels = $SizeBytes / ((Get-Variable -name  $AmigaDiskName).value.BytestoPixelFactor)
    if ($SizePixels -gt 4){
        $SizePixels -= 4
    }

    # $Script:GUICurrentStatus.AmigaPartitionsandBoundaries
    if ($AddType -eq 'AtEnd'){
        $LeftMargin = (Get-GUIPartitionStartEnd -PartitionType 'Amiga' -AmigaDiskName $AmigaDiskName).EndingPositionPixels
        $StartingPositionBytes = (Get-GUIPartitionStartEnd -PartitionType 'Amiga' -AmigaDiskName $AmigaDiskName).EndingPositionBytes
        # Write-debug "Left Margin is: $LeftMargin. Starting Position Bytes is: $StartingPositionBytes"
    }
    else{
        $PartitionNameNexttoDetails = ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries| Where-Object {$_.PartitionName -eq $PartitionNameNextto}) 
        if ($AddType -eq 'Right'){
            $LeftMargin = $PartitionNameNexttoDetails.RightMargin
            $StartingPositionBytes = $PartitionNameNexttoDetails.EndingPositionBytes
        }
        elseif ($AddType -eq 'Left'){
            $LeftMargin = $PartitionNameNexttoDetails.LeftMargin - ($SizeBytes/((Get-Variable -Name $AmigaDiskName).Value.BytestoPixelFactor))
            $StartingPositionBytes = $PartitionNameNexttoDetails.StartingPositionBytes - $SizeBytes
        }
    }

    if ($LoadSettings){
        $NewPartitionName = $NewPartitionNameFromSettings
    }
    else {
        $PartitionNumber = (Get-Variable -Name $AmigaDiskName).Value.NextPartitionNumber
        $NewPartitionName = ($AmigaDiskName+'_Partition_'+$PartitionNumber)
    }

    # Write-debug "New Partition Name is: $NewPartitionName "

    if ($DefaultPartition){
        Set-Variable -name $NewPartitionName -Scope script -value (New-GUIPartition -PartitionName $NewPartitionName -DefaultPartition -PartitionType 'Amiga' -PartitionTypeAmiga $PartitionTypeAmiga)
    }
    else {
        Set-Variable -name $NewPartitionName -Scope script -value (New-GUIPartition -PartitionName $NewPartitionName -PartitionType 'Amiga' -PartitionTypeAmiga $PartitionTypeAmiga)
    }

    if ($ImportedFilesPath){
        (Get-Variable -Name $NewPartitionName).Value.ImportedFilesPath = $ImportedFilesPath
        (Get-Variable -Name $NewPartitionName).Value.ImportedFilesSpaceBytes = [int64]$ImportedFilesSpaceBytes
    }

    (Get-Variable -Name $NewPartitionName).Value.Margin = [System.Windows.Thickness]"$LeftMargin,0,0,0"
    (Get-Variable -Name $NewPartitionName).Value.PartitionSizeBytes = [int64]$SizeBytes
    (Get-Variable -Name $NewPartitionName).Value.StartingPositionBytes = $StartingPositionBytes
    
    (Get-Variable -Name $NewPartitionName).Value.DeviceName = $DeviceName
    (Get-Variable -Name $NewPartitionName).Value.VolumeName = $VolumeName
    (Get-Variable -Name $NewPartitionName).Value.Buffers = $Buffers
    (Get-Variable -Name $NewPartitionName).Value.DosType = $DosType
    (Get-Variable -Name $NewPartitionName).Value.Mask = $Mask
    (Get-Variable -Name $NewPartitionName).Value.MaxTransfer = $MaxTransfer
    (Get-Variable -Name $NewPartitionName).Value.Bootable = $Bootable
    (Get-Variable -Name $NewPartitionName).Value.NoMount = $NoMount
    (Get-Variable -Name $NewPartitionName).Value.Priority = $Priority

    (Get-Variable -Name $NewPartitionName).Value.ColumnDefinitions[1].Width = $SizePixels
    
    (Get-Variable -Name $AmigaDiskName).Value.AddChild(((Get-Variable -name $NewPartitionName).value))

    if (-not ($LoadSettings)){
        (Get-Variable -Name $AmigaDiskName).Value.NextPartitionNumber ++
    }
    
    if ($WPF_DP_Amiga_GroupBox.Visibility -eq 'Visible'){     
        $WPF_DP_DiskGrid_Amiga.UpdateLayout()
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
    }
    
}


