function Write-ImageCreation {
    param (
  
   )
   
   $Script:Settings.TotalNumberofTasks = 7
   If ($Script:GUIActions.InstallOSFiles -eq $false){
      $Script:Settings.TotalNumberofTasks -= 2
   }
    
   $Script:Settings.CurrentTaskNumber = 1
   
   if ($Script:GUICurrentStatus.RunMode -eq 'CommandLine'){
      get-process -id $Pid | set-windowstate -State SHOWDEFAULT -SuppressErrors
   }

   $KickstartVersionForImage = [system.version]$Script:GUIActions.KickstartVersiontoUse

   $Script:GUICurrentStatus.ProgressBarMarkers = $Script:Settings.ProgressBarMarkers.where({ $KickstartVersionForImage.major -eq $_.KickstartVersion.major -and $KickstartVersionForImage.minor -eq $_.KickstartVersion.Minor })[0]
   
   $fileCount = 0
   
   $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | ForEach-Object {
      if ($_.Partition.ImportedFilesPath){
         $fileCount += (Get-ChildItem -Path $_.Partition.ImportedFilesPath -File -Recurse).Count
      }
   }
      
   $Script:GUICurrentStatus.ProgressBarMarkers.WriteFilestoDisk += $fileCount
       
   $Script:GUICurrentStatus.StartTimeForRunningInstall = (Get-Date -Format HH:mm:ss)
     
   write-informationMessage -Message "Started processing at: $($Script:GUICurrentStatus.StartTimeForRunningInstall)"

   Write-Emu68ImagerLog -Continue

   Write-AmigaFilestoInterimDrive
   
   $Script:Settings.CurrentTaskName = "Preparing  commands for setting up image or disk"
   Write-StartTaskMessage
   
   $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage = [System.Collections.Generic.List[PSCustomObject]]::New() 
   $Script:GUICurrentStatus.HSTImagerCommandstoProcess.DiskStructures = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTImagerCommandstoProcess.WriteFilestoDisk = [System.Collections.Generic.List[PSCustomObject]]::New() 
   
   $Script:Settings.TotalNumberofSubTasks = 6
   $Script:Settings.CurrentSubTaskNumber = 1
   
   Get-NewDiskorImageCommands 
      
   $Script:Settings.CurrentSubTaskNumber ++
   $Script:Settings.CurrentSubTaskName = "Getting Commands for Initialising disk"
   
   Write-StartSubTaskMessage
     
   Initialize-MBRDisk
     
   $Script:Settings.CurrentSubTaskNumber ++

   Get-DiskStructurestoMBRGPTDiskorImageCommands

   Get-CopyFilestoDiskCommands 

   Write-TaskCompleteMessage 

  
   $Script:Settings.CurrentTaskName = "Processing Commands to set up Disk and copy files"
   Write-StartTaskMessage

   Write-InformationMessage -Message "Disk size (Bytes) is: $($WPF_DP_Disk_GPTMBR.DiskSizeBytes)"

   Write-InformationMessage -Message "Running HST Imager. Note this step could take time depending on the size of your disk and/or if you have imported files"

   $HSTCommandstoRun = $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage + $Script:GUICurrentStatus.HSTImagerCommandstoProcess.DiskStructures + $Script:GUICurrentStatus.HSTImagerCommandstoProcess.WriteFilestoDisk

   Start-HSTCommands -HSTScript $HSTCommandstoRun -section "NewDiskorImage;DiskStructures;CopyImportedFiles;WriteFilestoDisk" -ActivityDescription 'Processing commands' -ReportTime

   Write-TaskCompleteMessage 

   $Script:GUICurrentStatus.EndTimeForRunningInstall = (Get-Date -Format HH:mm:ss)
   $ElapsedTime = (New-TimeSpan -Start $Script:GUICurrentStatus.StartTimeForRunningInstall -end $Script:GUICurrentStatus.EndTimeForRunningInstall).TotalSeconds
   
   Write-InformationMessage -Message "Processing Complete!"    
   Write-InformationMessage -message "Started at: $($Script:GUICurrentStatus.StartTimeForRunningInstall) Finished at: $($Script:GUICurrentStatus.EndTimeForRunningInstall). Total time to run (in seconds) was: $ElapsedTime" 
   Write-InformationMessage -message "The tool has finished running. A log file was created and has been stored in the log subfolder."
   Write-InformationMessage -message "The full path to the file is: $([System.IO.Path]::GetFullPath($Script:Settings.LogLocation))"

   Get-HSTCommandstoLog | Out-File $Script:Settings.LogLocation -Append -Encoding utf8 -Width 2000  

}
