function Get-RemovableMedia {
    param (
    )

    $ScriptDriveLetter = $Script:GUIActions.ScriptPath.substring(($Script:GUIActions.ScriptPath.IndexOf(':\'))-1,1)

    $ScriptDiskDrive = Get-WmiObject Win32_LogicalDiskToPartition | Where-Object { $_.Dependent -match "DeviceID=`"${ScriptDriveLetter}:`"" } |  ForEach-Object {
        if ($_.Antecedent -match 'Disk #(\d+)') { $Matches[1] }
    }

    $RemovableMediaList = @()
    foreach ($Disk in (Get-WmiObject Win32_DiskDrive)) {
        $DriveNumber = $Disk.DeviceID.replace("\\.\PHYSICALDRIVE","") 
        if ($DriveNumber -eq $ScriptDiskDrive) { continue }
        $hasMedia = ($Disk.size -gt 0)
        $IsVirtual = ($Disk.Model -match "Virtual|VMware|VBOX|osfdisk|Loop") 
        $isRemovable = ((($Disk.MediaType -eq "Removable Media") -or ($Disk.InterfaceType -eq "USB")) -and -not $IsVirtual)

        $isValidTarget = $isRemovable -or ($IsVirtual -and $Script:GUICurrentStatus.AllowVirtualDrives -eq $true)

        if ($isValidTarget -and $hasMedia){
            $SizeofDiskwithBuffer=($Disk.Size)-(3076*1024) 
            $RemovableMediaList += [PSCustomObject]@{
                DeviceID = $Disk.DeviceID
                Model = $Disk.Model
                SizeofDisk = $SizeofDiskwithBuffer/1024 # KiB
                EnglishSize = ([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString())
                FriendlyName = "Disk $DriveNumber $($Disk.Model) $([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString())GiB" 
                HSTDiskName = "\disk$DriveNumber"
                HSTDiskNumber = $DriveNumber
                DeviceisScriptRunDevice = ""
            }
            
        }
    }
           
    return $RemovableMediaList

}
