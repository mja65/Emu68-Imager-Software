                  
                                                  

function Write-HSTCommandstoLog {
    param (
        
        )
                                     
    "HST imager commands ran:" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "ExtractOS Files" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    $Script:GUICurrentStatus.HSTCommandstoProcess.ExtractOSFiles | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "Copy Icon Files" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    $Script:GUICurrentStatus.HSTCommandstoProcess.CopyIconFiles | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "New Disk or Image" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "Disk Structures" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "Write Files to Disk" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8     
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8      
    $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    "Adjust Parameters on Imported RDB Partitions" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8     
    "" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    $Script:GUICurrentStatus.HSTCommandstoProcess.AdjustParametersonImportedRDBPartitions | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000      
    

    }              
