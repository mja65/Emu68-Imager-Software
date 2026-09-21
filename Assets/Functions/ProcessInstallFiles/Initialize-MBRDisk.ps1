function Initialize-MBRDisk {
    param (
    
    )
    $HSTOutputPath = if ($Script:GUIActions.OutputType -eq "Image") { "`"$($Script:GUIActions.OutputPath)`""} else { $Script:GUIActions.OutputPath }
    $MessagetoWrite = if ($Script:GUIActions.OutputType -eq "Image") { "Adding command to initialise disk for disk image file at path: $($Script:GUIActions.OutputPath)"} else {"Adding command to initialise disk for disk at path: $($Script:GUIActions.OutputPath)"}
   
    Write-InformationMessage -Message $MessagetoWrite 
   
    $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
        Command = "mbr init $HSTOutputPath"
        Sequence = 3           
    } 

}
