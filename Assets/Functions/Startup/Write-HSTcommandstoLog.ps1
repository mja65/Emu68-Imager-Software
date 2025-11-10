                  
                                                  

function Write-HSTCommandstoLog {
    param (
        
        )
        $FullListofCommands =   $Script:GUICurrentStatus.HSTCommandstoProcess.ExtractOSFiles +`
                            $Script:GUICurrentStatus.HSTCommandstoProcess.CopyIconFiles + `
                            $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage +`
                            $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures + `
#                                $Script:GUICurrentStatus.HSTCommandstoProcess.CopyImportedFiles +`
                            $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk +`
                            $Script:GUICurrentStatus.HSTCommandstoProcess.AdjustParametersonImportedRDBPartitions       
                            
                            
    "HST imager commands ran:" |Out-File $Script:Settings.LogLocation -Append -Encoding utf8
     $FullListofCommands.Command | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000

    }              
