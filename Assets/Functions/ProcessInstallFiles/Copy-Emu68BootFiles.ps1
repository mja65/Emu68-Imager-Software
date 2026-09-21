function Copy-EMU68BootFiles {
    param (

    )
       
    $PowershellDiskNumber = $Script:GUIActions.OutputPath.Substring(5,($Script:GUIActions.OutputPath.length-5))
    $DriveLetterFound = (Get-Partition -DiskNumber $PowershellDiskNumber -PartitionNumber 1).DriveLetter
    if ($DriveLetterFound){
        $Emu68BootPath = "$($DriveLetterFound):\"
    } 
    else {
        Add-PartitionAccessPath -DiskNumber $PowershellDiskNumber -PartitionNumber 1 -AssignDriveLetter 
        $Emu68BootPath = "$((Get-Partition -DiskNumber $PowershellDiskNumber -PartitionNumber 1).DriveLetter):\"            
    }
    
    $null = Copy-Item "$($Script:Settings.InterimAmigaDrives)\Emu68Boot\*" -Destination $Emu68BootPath -Recurse -force
    $null = Copy-Item -LiteralPath $Script:GUIActions.FoundKickstarttoUse.KickstartPath -Destination "$Emu68BootPath\$($Script:GUIActions.FoundKickstarttoUse.Fat32Name)"
    
}
