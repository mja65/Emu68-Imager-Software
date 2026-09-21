function Add-GUIPartitiontoGPTMBRDisk {
    param (
        [Switch]$LoadSettings,
        $NewPartitionNameFromSettings,
        $PartitionType,
        $PartitionSubType,
        $AddType,
        $PartitionNameNextto, 
        $SizeBytes,
        [Switch]$DefaultPartition,
        [switch]$ImportedPartition,
        $ImportedPartitionMethod,
        [switch]$DerivedImportedPartition,
        $PathtoImportedPartition,
        $VolumeName,
        $StartingPositionBytes
    )

    # $PartitionType = 'MBR-FAT32'
    # $PartitionType = 'ID76'
    # $NewPartitionNumber = '1'
    # $SizePixels = 100
    # $LeftMargin = 0
    # $PartitionNameNextto = 'WPF_DP_Partition_ID76_1'

    if ($ImportedPartition -eq $true){
        # Write-debug "Importing MBR Partition $PathtoImportedPartition"
    }
    
    $SizePixels = $SizeBytes / $Script:WPF_DP_Disk_GPTMBR.BytestoPixelFactor
    if ($SizePixels -gt 4){
        $SizePixels -= 4
    }
    
    if ($PartitionType -eq 'MBR'){
        $NewPartitionNumber = $Script:WPF_DP_Disk_GPTMBR.NextPartitionMBRNumber
    }
    elseif ($PartitionType -eq 'GPT') {
        Write-ErrorMessage -Message "Error in coding - Add-GUIPartitiontoGPTMBRDisk!"
        $WPF_MainWindow.Close()
        exit
    }
    
    if ($LoadSettings){
        $NewPartitionName = $NewPartitionNameFromSettings
    }
    else{
        $NewPartitionName = "$($Script:DP_Settings.PartitionPrefix)$($PartitionType)_$($NewPartitionNumber)"
        
    }

    # Write-debug "New Partition Name is: $NewPartitionName" 

    if ($AddType -eq 'AtEnd' -or $AddType -eq 'Initial'){
        $LeftMargin = (Get-GUIPartitionStartEnd -PartitionType 'MBR').EndingPositionPixels
        $StartingPositionBytes = (Get-GUIPartitionStartEnd -PartitionType 'MBR').EndingPositionBytes
    }
    else{
        $PartitionNameNexttoDetails = (Get-AllGUIPartitionBoundaries -GPTMBR -Amiga | Where-Object {$_.PartitionName -eq $PartitionNameNextto}) 
        if ($AddType -eq 'Right'){
            $LeftMargin = $PartitionNameNexttoDetails.RightMargin
            $StartingPositionBytes = $PartitionNameNexttoDetails.EndingPositionBytes
        }
        elseif ($AddType -eq 'Left'){
            $LeftMargin = $PartitionNameNexttoDetails.LeftMargin - ($SizeBytes/$WPF_DP_Disk_GPTMBR.BytestoPixelFactor)
            $StartingPositionBytes = $PartitionNameNexttoDetails.StartingPositionBytes - $SizeBytes
        }
        elseif ($AddType -eq 'SpecificPosition'){
            $CheckLastPartitioninCaseofOverrrun = (Get-GUIPartitionStartEnd -PartitionType 'MBR').EndingPositionPixels
            if ($CheckLastPartitioninCaseofOverrrun -lt $StartingPositionBytes/$WPF_DP_Disk_GPTMBR.BytestoPixelFactor){
                $LeftMargin = $CheckLastPartitioninCaseofOverrrun
            }
            else{
                $LeftMargin =  $StartingPositionBytes/$WPF_DP_Disk_GPTMBR.BytestoPixelFactor
            }

        }
    }
    if ($DefaultPartition) {
        $NewPartition = New-GUIPartition -PartitionName $NewPartitionName -PartitionType $PartitionType -PartitionSubType $PartitionSubType -DefaultPartition 

    }
    elseif ($ImportedPartition){
        $NewPartition = New-GUIPartition -PartitionName $NewPartitionName -PartitionType $PartitionType -PartitionSubType $PartitionSubType -ImportedPartition -ImportedPartitionMethod $ImportedPartitionMethod
    }
    else{
        $NewPartition = New-GUIPartition -PartitionName $NewPartitionName -PartitionType $PartitionType -PartitionSubType $PartitionSubType
    }
    
    $NewPartition.PartitionSizeBytes = [int64]$SizeBytes
    if ($VolumeName){
        $NewPartition.VolumeName = $VolumeName
    }
    $NewPartition.StartingPositionBytes = [int64]$StartingPositionBytes
    $NewPartition.StartingPositionSector = [int64]($StartingPositionBytes/$Script:Settings.MBRSectorSizeBytes)

    if ($ImportedPartition){
        $NewPartition.ImportedPartition = $true
        $NewPartition.ImportedPartitionMethod = $ImportedPartitionMethod
        $NewPartition.ImportedPartitionPath = $PathtoImportedPartition
    }

    $NewPartition.Margin = [System.Windows.Thickness]"$LeftMargin,0,0,0"
    
    $NewPartition.ColumnDefinitions[1].Width = $SizePixels

    Set-Variable -name $NewPartitionName -Scope Script -Value ((Get-Variable -Name NewPartition).Value)
    (Get-Variable -Name $NewPartitionName).Value.Name = $NewPartitionName
 
    $PSCommand = @"
    
        `$Script:WPF_DP_DiskGrid_GPTMBR.AddChild(`$$NewPartitionName)

"@

    Invoke-Expression $PSCommand  
   
    If ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'ID76' -and (-not ($LoadSettings)) -and (-not ($ImportedPartition))){
       
        Add-AmigaDisktoID76Partition -ID76PartitionName $NewPartitionName
        if ($DefaultPartition -eq $true){

            $SystemDefaultValues = (Get-InputFileCSV -CSV 'DiskDefaults') | Where-Object {$_.Type -eq "Amiga" -and $_.Disk -eq 'System'}
            $WorkDefaultValues = (Get-InputFileCSV -CSV 'DiskDefaults') | Where-Object {$_.Type -eq "Amiga" -and $_.Disk -eq 'Work'}

            Add-GUIPartitiontoAmigaDisk -AmigaDiskName ($NewPartitionName+'_AmigaDisk') -SizeBytes (Get-AmigaNearestSizeBytes -RoundDown -SizeBytes $Script:SDCardMinimumsandMaximums.WorkbenchDefault) -AddType 'AtEnd' -PartitionTypeAmiga 'Workbench' -DeviceName $SystemDefaultValues.DeviceName -VolumeName $SystemDefaultValues.VolumeName  -Buffers $SystemDefaultValues.Buffers -MaxTransfer $SystemDefaultValues.MaxTransfer -DosType $SystemDefaultValues.DosType -Bootable $SystemDefaultValues.BootableFlag -NoMount $SystemDefaultValues.NoMountFlag -Priority ([int]$SystemDefaultValues.Priority) -mask ($SystemDefaultValues.Mask)
            
            $RemainingSpace = $SizeBytes-1032192- (Get-AmigaNearestSizeBytes -RoundDown -SizeBytes $Script:SDCardMinimumsandMaximums.WorkbenchDefault) 

            $NumberofPartitions = [math]::Ceiling($RemainingSpace/$Script:SDCardMinimumsandMaximums.PFS3Maximum)

            $SpacetoAllocatetoAmigaWorkPartition =  Get-AmigaNearestSizeBytes -RoundDown -SizeBytes ($RemainingSpace/$NumberofPartitions) 
            $LastPartitionSpacetoAllocate = Get-AmigaNearestSizeBytes -RoundDown -SizeBytes ($RemainingSpace-($SpacetoAllocatetoAmigaWorkPartition*($NumberofPartitions-1)))
                     
            # $RemainingSpacetoAllocate = $SpacetoAllocatetoAmigaWorkPartition

            for ($i = 1; $i -le $NumberofPartitions; $i++) {
                If ($NumberofPartitions -eq 1){
                    $WorkVolumeName = $WorkDefaultValues.VolumeName
                    $DeviceName = $WorkDefaultValues.DeviceName
                }
                else{
                    $WorkVolumeName = "$($WorkDefaultValues.VolumeName)_$i"                    
                    $DeviceName = "$($WorkDefaultValues.DeviceName -replace '\d+$', '')$i"
                }

                if ($i -eq $NumberofPartitions){
                    $SpacetoAllocatetoAmigaWorkPartition = $LastPartitionSpacetoAllocate
                }

                Add-GUIPartitiontoAmigaDisk -AmigaDiskName ($NewPartitionName+'_AmigaDisk') -SizeBytes $SpacetoAllocatetoAmigaWorkPartition -PartitionTypeAmiga 'Work' -AddType 'AtEnd' -VolumeName $WorkVolumeName -DeviceName $DeviceName -Buffers $WorkDefaultValues.Buffers -MaxTransfer $WorkDefaultValues.MaxTransfer -DosType $WorkDefaultValues.DosType -Bootable $WorkDefaultValues.BootableFlag -NoMount $WorkDefaultValues.NoMountFlag -Priority ([int]$WorkDefaultValues.Priority) -mask $WorkDefaultValues.Mask
            }
            
        }
       # Set-DiskCoordinates -prefix 'WPF_UI_DiskPartition_' -PartitionPrefix 'Partition_' -PartitionType 'Amiga' -AmigaDisk ((Get-Variable -name ($NewPartitionName+'_AmigaDisk')).value)
        #Set-AmigaDiskSizeBytes -ID76PartitionName $NewPartitionName -AmigaDisk ((Get-Variable -name ($NewPartitionName+'_AmigaDisk')).value)
    }
    
    if (-not ($LoadSettings)){
        if ($PartitionType -eq 'MBR'){
            $NewPartitionNumber = $Script:WPF_DP_Disk_GPTMBR.NextPartitionMBRNumber
            $Script:WPF_DP_Disk_GPTMBR.NextPartitionMBRNumber ++
            $Script:WPF_DP_Disk_GPTMBR.NumberofPartitionsMBR ++
        }
        elseif ($PartitionType -eq 'GPT'){
            Write-ErrorMessage -Message "Coding Error - Add-GUIPartitiontoGPTMBRDisk!"
            $WPF_MainWindow.Close()
            exit
        }

    }
    $WPF_DP_DiskGrid_GPTMBR.UpdateLayout()
    $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -GPTMBR)

}
