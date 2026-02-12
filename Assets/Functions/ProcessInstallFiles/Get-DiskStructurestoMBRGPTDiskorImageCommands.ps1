function Get-DiskStructurestoMBRGPTDiskorImageCommands {
    param (
        
    )

    
    $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures = [System.Collections.Generic.List[PSCustomObject]]::New()
    $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk = [System.Collections.Generic.List[PSCustomObject]]::New() 

    if ($Script:GUIActions.DiskTypeSelected -eq 'PiStorm - MBR'){
        $MBRPartitionstoAddtoDisk = @($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries)
        if (-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)){
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }      
        $RDBPartitionstoAddtoDisk = @($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)
    }
    elseif ($Script:GUIActions.DiskTypeSelected -eq 'PiStorm - GPT'){
        Write-ErrorMessage -Message "Error in Coding - WPF_Window_Button_Run !"
        $WPF_MainWindow.Close()
        exit
    }
    elseif ($Script:GUIActions.DiskTypeSelected -eq 'Amiga - RDB'){
        Write-ErrorMessage -Message "Error in Coding - WPF_Window_Button_Run !"
        $WPF_MainWindow.Close()
        exit
    }
        
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Getting commands to create MBR Partitions"
    
    Write-StartSubTaskMessage

    $MBRPartitionCounter = 1
    
    $StartingSector = $Script:Settings.MBRFirstPartitionStartSector

    foreach ($MBRPartition in $MBRPartitionstoAddtoDisk) {
        if ($MBRPartition.Partition.PartitionSubType -eq 'FAT32'){
            $PartitionTypetoUse = "0xb"
    
        }
        elseif ($MBRPartition.Partition.PartitionSubType -eq 'ID76'){
            $PartitionTypetoUse = "0x76"            
        }
        Write-InformationMessage -Message "Adding command to create partition #$MBRPartitionCounter of type $PartitionTypetoUse"

        $MBRPartitionStartSector = $MBRPartition.Partition.StartingPositionSector + $StartingSector
     
        $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
            Command = "mbr part add `"$($Script:GUIActions.OutputPath)`" $PartitionTypetoUse $([int64]($MBRPartition.Partition.partitionsizebytes)) --start-sector $([int64]$MBRPartitionStartSector)"
            Sequence = 1      
        }  
        if ($MBRPartition.Partition.PartitionSubType -eq 'FAT32'){
            Write-InformationMessage -Message "Adding command to format FAT32 partition for partition #$MBRPartitionCounter"
            $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
                Command = "mbr part format `"$($Script:GUIActions.OutputPath)`" $MBRPartitionCounter $($MBRPartition.Partition.VolumeName)"
                Sequence = 1      
            }  
        }
        $MBRPartitionCounter ++
    }

    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Getting commands to create RDB Partitions"

    Write-StartSubTaskMessage
    
    $FileSystemstoAdd = [System.Collections.Generic.List[PSCustomObject]]::New()

    Write-InformationMessage -Message "Determining Filesystems to add to disk"
    foreach ($RDBPartition in $RDBPartitionstoAddtoDisk){        
        $FileSystemstoAdd.add([PSCustomObject]@{
            GPTMBRPartition = $RDBPartition.Partitionname.Substring(0,($RDBPartition.Partitionname.IndexOf('_AmigaDisk_Partition_')))
            DosType = $RDBPartition.Partition.DosType
            FileSystemPath = $null
            FileSystemName = $null
        })
    }
   
   $FileSystemstoAdd = $FileSystemstoAdd | Select-Object 'GPTMBRPartition','DosType','FileSystemPath','FileSystemName'  -Unique

   $HashTableforFileSystemPath = @{} # Clear Hash
   Get-AvailableAmigaFileSystems -FilesystemsbyDosTypesFLAG | ForEach-Object {
       $HashTableforFileSystemPath[$_.DosType] = @($_.Filesystempath)
   }
    
   $FileSystemstoAdd | ForEach-Object {
       if ($HashTableforFileSystemPath.ContainsKey($_.DosType)){
           $_.FileSystemPath = $HashTableforFileSystemPath.($_.DosType)[0]
           $_.FileSystemName = split-path -Path $_.FileSystemPath -Leaf
       }
   }

    Write-InformationMessage -Message "Preparing HST Commands to run"
  
   $Script:GUICurrentStatus.PathstoRDBPartitions = [System.Collections.Generic.List[PSCustomObject]]::New()
   
   $MBRPartitionCounter = 1
  
   foreach ($MBRPartition in $MBRPartitionstoAddtoDisk) {
       if ($MBRPartition.Partition.PartitionSubType -eq 'FAT32'){
           Write-InformationMessage -Message "Skipping Partition $($MBRPartition.PartitionName) - MBR Partition Number: $MBRPartitionCounter"
       }       
       elseif ($MBRPartition.Partition.PartitionSubType -eq 'ID76'){
           $RDBPartitionCounter = 1       
           Write-InformationMessage -Message "Preparing commands to set up Amiga Disk for $($MBRPartition.PartitionName) - MBR Partition Number: $MBRPartitionCounter"
           if ($MBRPartition.Partition.ImportedPartition -ne $true){
               $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
                   Command = "rdb init `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter`""
                   Sequence = 3    
               }  
               foreach ($FileSystem in $FileSystemstoAdd){
                   if ($FileSystem.GPTMBRPartition -eq $MBRPartition.PartitionName){
                    $DosTypetoUse = $FileSystem.DosType.Replace("\","")
                    Write-InformationMessage -Message "Adding filesystem `"$($FileSystem.FileSystemName)`" to Disk"
                       $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
                           Command = "rdb filesystem add `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter`" `"$($FileSystem.FileSystemPath)`" $DosTypetoUse"    
                           Sequence = 3      
                       }            
                   }               
               }
               foreach ($RDBPartition in $RDBPartitionstoAddtoDisk) {
                    if (($RDBPartition.PartitionName -split '_AmigaDisk_')[0] -eq $MBRPartition.PartitionName){
                        $Script:GUICurrentStatus.PathstoRDBPartitions  += [PSCustomObject]@{
                            MBRPartitionNumber = $MBRPartitionCounter
                            RDBPartitionNumber = $RDBPartitionCounter
                            DeviceName = $($RDBPartition.Partition.DeviceName)
                            VolumeName = $($RDBPartition.Partition.VolumeName)
                        }               
                           $DosTypetoUse = $RDBPartition.Partition.DosType.replace('\','')
                           $MasktoUse = $RDBPartition.Partition.mask
                           $MaxTransfertoUse = $RDBPartition.Partition.MaxTransfer 
                           $BufferstoUse = $RDBPartition.Partition.Buffers
                           if ($RDBPartition.Partition.NoMount -eq 'True'){
                               $NoMountflagtouse = "--no-mount True " #Need space in case some partitions don't have flag
                           }
                           else {
                               $NoMountflagtouse = "--no-mount False " 
                           }
                           if ($RDBPartition.Partition.Bootable -eq 'True'){
                               $bootableflagtouse = "--bootable True " #Need space in case some partitions don't have flag
                           }
                           else {
                               $bootableflagtouse = "--bootable False "
                           }
                           $BootPrioritytouse = $RDBPartition.Partition.Priority
                           If ($RDBPartition.Partition.ImportedFilesPath){
                               if (test-path ($RDBPartition.Partition.ImportedFilesPath)){
                                   if ($Script:GUIActions.InstallOSFiles -eq $true){
                                       if (test-path "$($Script:Settings.TempFolder)\ImportedFiles.info"){
                                           $null = Remove-Item "$($Script:Settings.TempFolder)\ImportedFiles.info"                                   
                                       }                                                                  
                                       $null = Copy-Item "$($Script:Settings.TempFolder)\IconFiles\NewFolder\NewFolder.info" "$($Script:Settings.TempFolder)\ImportedFiles.info"   
                                   }                                   
                                   Write-InformationMessage -Message "Adding command to import files from $($RDBPartition.Partition.ImportedFilesPath) to RDB Partition $($RDBPartition.Partition.DeviceName)"
                                   $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                                       Command = "fs mkdir `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter\rdb\$($RDBPartition.Partition.DeviceName)\ImportedFiles`""
                                       Sequence = 5                                            
                                   }  
                                   $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                                       Command = "fs copy `"$($RDBPartition.Partition.ImportedFilesPath)\`*`" `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter\rdb\$($RDBPartition.Partition.DeviceName)\ImportedFiles`" --makedir --recursive TRUE --force TRUE"
                                       Sequence = 5      
                                   }  
                                   if ($Script:GUIActions.InstallOSFiles -eq $true){
                                       Write-InformationMessage -Message "Adding command to create .info file for imported files folder"
                                       $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                                           Command = "fs copy `"$([System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\ImportedFiles.info"))`" `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter\rdb\$($RDBPartition.Partition.DeviceName)`" --makedir --recursive TRUE --force TRUE"
                                           Sequence = 5      
                                       }                                     
                                   }
                                   else {
                                    Write-WarningMessage -Message "Not creating .info file for imported files folder as icons not available (you haven't installed an OS)"
                                   }
                               }
                               else {
                                Write-ErrorMessage -Message "Path for imported files no longer exists! Cannot import files"
                               }
                           }
                           Write-InformationMessage -Message "Adding command to create partition for Device:$($RDBPartition.Partition.DeviceName) of size(bytes):$($RDBPartition.Partition.PartitionSizeBytes)"
                           $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
                               Command = "rdb part add `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter`" $($RDBPartition.Partition.DeviceName) $DosTypetoUse $($RDBPartition.Partition.PartitionSizeBytes) --buffers $bufferstouse --max-transfer $maxtransfertouse --mask $masktouse $nomountflagtouse$bootableflagtouse--boot-priority $BootPrioritytouse"
                               Sequence = 4      
                            }
                            Write-InformationMessage -Message "Adding command to format Device:$($RDBPartition.Partition.DeviceName) with volume name:$($RDBPartition.Partition.VolumeName)"
                            $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures += [PSCustomObject]@{
                                Command = "rdb part format `"$($Script:GUIActions.OutputPath)\mbr\$MBRPartitionCounter`" $RDBPartitionCounter $($RDBPartition.Partition.VolumeName)"
                                Sequence = 4      
                            }
                           $RDBPartitionCounter++   
                    }   
                }
           }
        }  
       $MBRPartitionCounter ++
    }    

}