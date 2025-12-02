function Get-CopyFilestoAmigaDiskCommands {
    param (
        $OutputLocationType 
    )
    
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Getting commands for copying Files to Amiga Partitions" 
    
    Write-StartSubTaskMessage
    
    $HashTableforPathstoRDBPartitions = @{} # Clear Hash

    $Script:GUICurrentStatus.PathstoRDBPartitions | ForEach-Object {
        $HashTableforPathstoRDBPartitions[$_.VolumeName] = @($_.RDBPartitionNumber,$_.DeviceName,$_.MBRPartitionNumber) 
    }
    
    $AmigaDiskstoWrite =  Get-InputCSVs -Diskdefaults | Where-Object {$_.Disk -ne "EMU68BOOT"} | Select-Object 'Disk','DeviceName','VolumeName' 

    $AmigaDiskstoWrite | ForEach-Object {
        if ($HashTableforPathstoRDBPartitions.ContainsKey($_.VolumeName)){
            $MBRNumber = $HashTableforPathstoRDBPartitions.($_.VolumeName)[2]
           # $RDBNumber = $HashTableforPathstoRDBPartitions.($_.VolumeName)[0]
            $RDBDeviceName = $HashTableforPathstoRDBPartitions.($_.VolumeName)[1]
            $DestinationPath = "$($Script:GUIActions.OutputPath)\MBR\$MBRNumber\rdb\$RDBDeviceName"
            $CopyFilestoDevice =$true
        }
        else {
            $CopyFilestoDevice =$false
        }
        if ($_.Disk -eq "System"){
            $ReplacementString = [System.IO.Path]::GetFullPath("$($Script:Settings.InterimAmigaDrives)\System")
            $Script:GUICurrentStatus.HSTCommandstoProcess.WriteDirectFilestoDisk | ForEach-Object {
                $_.Command = $($_.Command.Replace($ReplacementString,$DestinationPath)) 
            }
        }
        if ($CopyFilestoDevice -eq $true){
            $SourcePath = "$([System.IO.Path]::GetFullPath($Script:Settings.InterimAmigaDrives))\$($_.Disk)\`*"
            if (Test-path (Split-Path -Path $SourcePath -Parent)){
                Write-InformationMessage -Message "Adding commands for copying file(s) to $RDBDeviceName for Drive $($_.Disk)"
                $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                    Command = "fs copy `"$SourcePath`" `"$DestinationPath`" --makedir TRUE --recursive TRUE --uaemetadata UaeFsDb"                
                    Sequence = 5
                }
            }
        }
    }

    $HashTableforAmigaDiskstoWrite = @{} # Clear Hash
    $AmigaDiskstoWrite  | ForEach-Object {
        $HashTableforAmigaDiskstoWrite[$_.VolumeName] = @($_.Disk) 
    }

    $DiskIconsPath = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\IconFiles\DiskIconstoUse")
    
    if ($Script:GUIActions.InstallOSFiles -eq $true){

        $Script:GUICurrentStatus.PathstoRDBPartitions | ForEach-Object {
            $SourcePath = "$DiskIconsPath\$($_.DeviceName)\disk.info"
            $DestinationPath = "$($Script:GUIActions.OutputPath)\MBR\$($_.MBRPartitionNumber)\rdb\$($_.DeviceName)"           
            Write-InformationMessage -Message "Adding commands for copying icon file(s) to $($_.DeviceName)"
            $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                Command = "fs copy `"$SourcePath`" `"$DestinationPath`""
                Sequence = 6
            }
           
        }

    }
    else {
        Write-WarningMessage -Message "Not creating disk.info files for Amiga disks as icons not available (you haven't installed an OS)"
        
    }
   
   
}
