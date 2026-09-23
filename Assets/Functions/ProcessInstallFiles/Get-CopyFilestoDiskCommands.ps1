function Get-CopyFilestoDiskCommands {
    param (

    )
        
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Getting commands for copying Files to Amiga Partitions" 
    
    Write-StartSubTaskMessage
    
    $FAT32Partitions = (@($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries)).Partition.where({$_.PartitionSubType -eq 'FAT32'})

    $MBRNumber = 1

    $FAT32Partitions.ForEach({
        $SourcePath = Join-PathMulti $Script:Settings.InterimAmigaDrives $_.VolumeName -UseFullPath
        $DestinationPath = "$($Script:GUIActions.OutputPath)\MBR\$MBRNumber"
        $HSTDestinationPath = if ($Script:GUIActions.OutputType -eq "Image") { "`"$DestinationPath`"" } else { $DestinationPath }
        #Write-debug "SourcePath is: $SourcePath DestinationPath is: $DestinationPath"
        Write-InformationMessage -Message "Adding commands for copying file(s) to $($_.VolumeName)"
        $Script:GUICurrentStatus.HSTImagerCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
            Command = "fs copy `"$SourcePath\`*`" $HSTDestinationPath --makedir TRUE --recursive TRUE --uaemetadata UaeFsDb --force TRUE"                
            Sequence = 5
        }        
        $MBRNumber ++
    })
    
    if ($Script:GUIActions.InstallOSFiles -ne $true){
        return
    }
        
    $Script:GUICurrentStatus.PathstoRDBPartitions.ForEach({
        $MBRNumber = $_.MBRPartitionNumber
        $RDBDeviceName = $_.DeviceName
        $DestinationPath = "$($Script:GUIActions.OutputPath)\MBR\$MBRNumber\rdb\$RDBDeviceName"
        $HSTDestinationPath = if ($Script:GUIActions.OutputType -eq "Image") { "`"$DestinationPath`"" } else { $DestinationPath }
        $DriveName = If ($_.DefaultWorkbenchPartition -eq $true) {"System"} else {$_.VolumeName}
        $SourcePath = Join-PathMulti $Script:Settings.InterimAmigaDrives $DriveName -UseFullPath
        #Write-debug "SourcePath is: $SourcePath DestinationPath is: $DestinationPath"
        Write-InformationMessage -Message "Adding commands for copying file(s) to $RDBDeviceName for Drive $DriveName"
        $Script:GUICurrentStatus.HSTImagerCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
            Command = "fs copy `"$SourcePath\`*`" $HSTDestinationPath --makedir TRUE --recursive TRUE --uaemetadata UaeFsDb --force TRUE"                
            Sequence = 5
        }
            
    })  
   
}
