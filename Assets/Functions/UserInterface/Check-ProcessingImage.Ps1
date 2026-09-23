function Check-ProcessingImage {
    param (

    )
    
    $Script:GUICurrentStatus.ProcessImageStatus = $true
           $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Clear()
               
           If (-not ($Script:GUIActions.KickstartVersiontoUse)){
               $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Start","No OS selected")
               $Script:GUICurrentStatus.ProcessImageStatus = $false
           }
           If (-not ($Script:GUIActions.FoundKickstarttoUse)){
               $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Start","Kickstart file has not been located")
               $Script:GUICurrentStatus.ProcessImageStatus = $false
           }
           if ($Script:GUIActions.InstallOSFiles -eq $true){
               If (-not ($Script:GUIActions.FoundInstallMediatoUse)){
                   $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Start","OS file(s) have not been located")
                   $Script:GUICurrentStatus.ProcessImageStatus = $false
               }   
           }
           
           If (-not ($Script:GUIActions.OutputPath)){
               $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","No Output location has been defined")
               $Script:GUICurrentStatus.ProcessImageStatus = $false
           }
           else {
               if ($Script:GUIActions.OutputType -eq 'Disk'){
                   $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries| ForEach-Object {
                       if ($_.Partition.ImportedPartition -eq $true -and $_.Partition.ImportedPartitionMethod -eq 'Direct'){
                          if ($_.Partition.ImportedPartitionPath -match $Script:GUIActions.OutputPath){
                              $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","The output location is the same physical disk set for one or more imported partitions")
                              $Script:GUICurrentStatus.ProcessImageStatus = $false
                          }
                       }         
                  }
               }
           }
    
           If (-not ($Script:GUIActions.DiskSizeSelected)){
               $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","Disk Partitioning has not been performed")
               $Script:GUICurrentStatus.ProcessImageStatus = $false
           }        
    
           if ($Script:GUIActions.DiskSizeSelected){
               
               if ($Script:GUIActions.InstallOSFiles -eq $true){
                   $SystemDeviceName = ((Get-InputFileCSV -CSV 'DiskDefaults') | Where-Object {$_.Disk -eq 'System'}).DeviceName
                   $DefaultID76Partition = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | Where-Object {$_.Partition.defaultgptmbrpartition -eq $true -and $_.Partition.PartitionSubType -eq 'ID76'}
               }
               
               $AmigaDriveDetailsToTest  = [System.Collections.Generic.List[PSCustomObject]]::New()
              
               Get-Variable -Include '*_amigadisk_Partition*' | ForEach-Object {            
                   $AmigaDriveDetailsToTest.add([PSCustomObject]@{
                       Disk = ($_.Name -split '_AmigaDisk_')[0]
                       DeviceName = $_.value.DeviceName
                       VolumeName = $_.value.VolumeName
                       Priority = $_.value.Priority
                       Bootable = $_.value.Bootable
                   })
               } 
                   
     
               if ($AmigaDriveDetailsToTest) {
                   
                   $IsBootableFound = $false
    
                   foreach ($drive in $AmigaDriveDetailsToTest) {
                       if ($drive.Bootable -eq $true) {
                           $IsBootableFound = $true
                           break
                       }
                   }
                   
                   if ($IsBootableFound -eq $false){
                        $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","There are no Amiga volumes set to be bootable.")
                   } 
    
                   if ($Script:GUIActions.InstallOSFiles -eq $true){
                                       
                       $TopPriorityonDefaultDrive = $AmigaDriveDetailsToTest | Where-Object {$_.Disk -eq $DefaultID76Partition.PartitionName} | Sort-Object 'Priority'| Select-Object -first 1
                       if ($TopPriorityonDefaultDrive.DeviceName -ne $SystemDeviceName) {
                           $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","The default system device $SystemDeviceName is not the highest priority device on the RDB.")
                           $Script:GUICurrentStatus.ProcessImageStatus = $false
                       }
                       else {
                           $AmigaDriveDetailsToTest | Where-Object {$_.Disk -eq $DefaultID76Partition.PartitionName} | ForEach-Object {
                               if (($_.Disk -eq $TopPriorityonDefaultDrive.Disk) -and ($_.DeviceName -ne $TopPriorityonDefaultDrive.DeviceName)  -and ($_.Priority -eq $TopPriorityonDefaultDrive.Priority)){
                                   $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","The default system device $SystemDeviceName is set to the same priority as one or more volumes on the same Amiga disk.")
                                   $Script:GUICurrentStatus.ProcessImageStatus = $false
                               }
                           }
                       }
                   }
    
           
                   $UniqueVolumeNamesPerDisk = $AmigaDriveDetailsToTest | Group-Object 'Disk','VolumeName' 
                   
                   $UniqueVolumeNamesPerDisk | ForEach-Object {
                       if ($_.Count -gt 1){       
                           $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","The same volume name `"$(($_.Name -split ', ')[1])`" has been used accross more than one partition on the same disk")
                           $Script:GUICurrentStatus.ProcessImageStatus = $false
                       }
                   }
                   
                   $UniqueDeviceNames = $AmigaDriveDetailsToTest | group-object 'DeviceName'
                   $UniqueDeviceNames | ForEach-Object {
                       if ($_.Count -gt 1){
                           $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","The same device name $($_.Name) has been used on more than one device. Note this could be on multiple disks")
                           $Script:GUICurrentStatus.ProcessImageStatus = $false
                       }      
                   }
    
               } 
               else {
                   $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("Disk Setup","No Amiga disks present")
                   $Script:GUICurrentStatus.ProcessImageStatus = $false
               }
               
           }

           if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode"){
               $CompletenessCheck = Confirm-CustomScreenModeComplete 
               if ($CompletenessCheck -ne "Complete"){
                $null = $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Rows.Add("ScreenMode","You are using a custom screenmode but have not configured it")
                $Script:GUICurrentStatus.ProcessImageStatus = $false
             }
           }
                     
           if ($Script:GUICurrentStatus.ProcessImageStatus -eq $false){
               $WPF_Window_Button_Run.Background = '#FFFF0000'
               $WPF_Window_Button_Run.foreground = '#FF000000'
               $WPF_Window_Button_Run.Content = 'Missing information in order to run tool! Press button to see further details'    
           }
           elseif ($Script:GUICurrentStatus.ProcessImageStatus -eq $true){
               $WPF_Window_Button_Run.Background = '#FF008000'
               $WPF_Window_Button_Run.foreground = '#FFFFFFFF'
               $WPF_Window_Button_Run.Content = 'Run Tool'    
           }    
}
