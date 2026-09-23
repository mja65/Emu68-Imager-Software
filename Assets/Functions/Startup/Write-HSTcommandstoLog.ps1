function Get-HSTCommandstoLog {
    param (
        
    )

@"
HST imager commands ran:

New Disk or Image:
$($Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage.Command -join [Environment]::NewLine)

Disk Structures:
$($Script:GUICurrentStatus.HSTImagerCommandstoProcess.DiskStructures.Command -join [Environment]::NewLine)

Write Files to Disk:
$($Script:GUICurrentStatus.HSTImagerCommandstoProcess.WriteFilestoDisk.Command -join [Environment]::NewLine)
"@
    
}              