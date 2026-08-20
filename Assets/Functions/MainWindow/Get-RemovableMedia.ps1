function Get-RemovableMedia {
    param (
    )
    $RemovableMediaList = [System.Collections.Generic.List[PSCustomObject]]::New()
    Get-CimInstance -ClassName Win32_DiskDrive | Where-Object {$_.MediaType -eq "Removable Media"} | ForEach-Object {
        $DriveStartpoint = $_.DeviceID.IndexOf('DRIVE')+5 # 5 is length of 'Drive'
        $DriveEndpoint = $_.DeviceID.Length
        $DriveLength = $DriveEndpoint- $DriveStartpoint
        $DriveNumber = $_.DeviceID.Substring($DriveStartpoint,$DriveLength)
        $SizeofDiskwithBuffer=($_.Size)-(3076*1024) 
        $RemovableMediaList += [PSCustomObject]@{
            DeviceID = $_.DeviceID
            Model = $_.Model
            SizeofDisk = $SizeofDiskwithBuffer/1024 # KiB
            EnglishSize = ([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString())
            FriendlyName = 'Disk '+$DriveNumber+' '+$_.Model+' '+([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString()+' GiB') 
            HSTDiskName = ('\disk'+$DriveNumber)
            HSTDiskNumber = $DriveNumber
            DeviceisScriptRunDevice = ''
        }
    
    }

    $ScriptDriveLetter = $Script:GUIActions.ScriptPath.substring(($Script:GUIActions.ScriptPath.IndexOf(':\'))-1,1)
 
    foreach ($RemovableMediaItem in $RemovableMediaList) {    
        $DriveNumber = $RemovableMediaItem.DeviceID.Substring($DriveStartpoint,$DriveLength)
        Get-Disk -Number $DriveNumber | Get-Partition | ForEach-Object {
            If ($_.DriveLetter -eq $ScriptDriveLetter){
                $RemovableMediaItem.DeviceisScriptRunDevice = 'TRUE'            
            } 
        }    
    
    }

    return ($RemovableMediaList | Where-Object {$_.DeviceisScriptRunDevice -ne "TRUE"})
}
