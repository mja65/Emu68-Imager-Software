function Copy-EMU68BootFiles {
    param (
        $OutputLocationType
    )
       
    if ($OutputLocationType -ne 'ImgImage'){
        $Script:Settings.CurrentTaskName = "Copying Files to Emu68 Boot Partition"
    }
    else {
        $Script:Settings.CurrentTaskName = "Getting commands for copying Files to Emu68 Boot Partition"
    }
    
    Write-StartTaskMessage

    $DiskIconsPath = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\IconFiles\DiskIconsToUse")

    if ($OutputLocationType -eq 'ImgImage'){
        
        $NoBOM_UTF8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText("$($Script:Settings.InterimAmigaDrives)\Emu68Boot\cmdline.txt", ("$(Get-Emu68BootCmdline -FirstBoot -SDLowSpeed -UnicamSettings)`n"), $NoBOM_UTF8)

        [System.IO.File]::WriteAllText("$($Script:Settings.InterimAmigaDrives)\Emu68Boot\cmdlineBAK.txt", ("$(Get-Emu68BootCmdline -SDLowSpeed -UnicamSettings)`n"), $NoBOM_UTF8)
        
        $SourcePath = "$([System.IO.Path]::GetFullPath("$($Script:Settings.InterimAmigaDrives)\Emu68Boot\"))*"  
        $DestinationPath = [System.IO.Path]::GetFullPath("$($Script:GUIActions.OutputPath)\MBR\1")
        $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
            Command = "fs copy $SourcePath $DestinationPath --makedir TRUE --recursive TRUE"
            Sequence = 6
        }
        if ($Script:GUIActions.InstallOSFiles -eq $true){
            $SourcePath = "$DiskIconsPath\SD0\disk.info" 
            $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk += [PSCustomObject]@{
                Command = "fs copy $SourcePath $DestinationPath --makedir TRUE --recursive TRUE"
                Sequence = 6
            }
        }
        else {
            Write-WarningMessage -Message "Not creating disk.info file for Emu68Boot folder as icons not available (you haven't installed an OS)"
        }

    }
    else {
        if ($OutputLocationType -eq 'VHDImage') {
            $IsMounted = (Get-DiskImage -ImagePath $Script:GUIActions.OutputPath -ErrorAction Ignore).Attached
                if ($IsMounted -eq $false){
                    $DeviceDetails = Mount-DiskImage -ImagePath $Script:GUIActions.OutputPath -NoDriveLetter
                    $PowershellDiskNumber = $DeviceDetails.Number                
                }
                else {
                    $PowershellDiskNumber = (Get-DiskImage -ImagePath $Script:GUIActions.OutputPath -ErrorAction Ignore).Number
                }
                Add-PartitionAccessPath -DiskNumber $PowershellDiskNumber -PartitionNumber 1 -AssignDriveLetter 
                $Emu68BootPath = "$((Get-Partition -DiskNumber $PowershellDiskNumber -PartitionNumber 1).DriveLetter):\"        
        }
        
        elseif ($OutputLocationType -eq 'Physical Disk'){
            $PowershellDiskNumber = $Script:GUIActions.OutputPath.Substring(5,($Script:GUIActions.OutputPath.length-5))
            $DriveLetterFound = (Get-Partition -DiskNumber $PowershellDiskNumber -PartitionNumber 1).DriveLetter
            if ($DriveLetterFound){
                $Emu68BootPath = "$($DriveLetterFound):\"
            } 
            else {
                Add-PartitionAccessPath -DiskNumber $PowershellDiskNumber -PartitionNumber 1 -AssignDriveLetter 
                $Emu68BootPath = "$((Get-Partition -DiskNumber $PowershellDiskNumber -PartitionNumber 1).DriveLetter):\"            
            }
        }
    
        $NoBOM_UTF8 = New-Object System.Text.UTF8Encoding($false)

        [System.IO.File]::WriteAllText("$($Script:Settings.InterimAmigaDrives)\Emu68Boot\cmdline.txt", ("$(Get-Emu68BootCmdline -FirstBoot -SDLowSpeed -UnicamSettings)`n"), $NoBOM_UTF8)
       
        [System.IO.File]::WriteAllText("$($Script:Settings.InterimAmigaDrives)\Emu68Boot\cmdlineBAK.txt", ("$(Get-Emu68BootCmdline -SDLowSpeed -UnicamSettings)`n"), $NoBOM_UTF8)
       
        $null = Copy-Item "$($Script:Settings.InterimAmigaDrives)\Emu68Boot\*" -Destination $Emu68BootPath -Recurse -force
        
        $null = Copy-Item -LiteralPath $Script:GUIActions.FoundKickstarttoUse.KickstartPath -Destination "$Emu68BootPath\$($Script:GUIActions.FoundKickstarttoUse.Fat32Name)"

        if ($Script:GUIActions.InstallOSFiles -eq $true){
            $null = Copy-Item "$DiskIconsPath\SD0\disk.info" -Destination "$Emu68BootPath"
        }
        else {
            Write-WarningMessage -Message "Not creating disk.info file for Emu68Boot folder as icons not available (you haven't installed an OS)"
        }

    }

}


