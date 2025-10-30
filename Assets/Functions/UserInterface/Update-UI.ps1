function Update-UI {
    param (
        [switch]$MainWindowButtons,
        [Switch]$Emu68Settings,
        [Switch]$DiskPartitionWindow,
        [Switch]$HighlightSelectedPartitions,
        [Switch]$UpdateInputBoxes,
        [Switch]$Buttons,
        [Switch]$PhysicalvsImage,
        [Switch]$CheckforRunningImage,
        [Switch]$FreeSpaceAlert,
        [Switch]$PackageSelectionWindow
    )

   
    # if (($Emu68Settings) -and (-not ($Script:GUICurrentStatus.CurrentWindow -eq 'Emu68Settings'))){
    #     return
    # }
    # if ((($DiskPartitionWindow) -or ($HighlightSelectedPartitions) -or ($UpdateInputBoxes) -or ($Buttons)) -and (-not ($Script:GUICurrentStatus.CurrentWindow -eq 'DiskPartition'))){
    #     return
    # }

    
    if ($PackageSelectionWindow){
        if ($Script:GUICurrentStatus.PackagesChanged -ne $true -and $Script:GUICurrentStatus.IconsChanged -ne $true){
            $WPF_PackageSelection_PackageSelection_Label.Text = "Note: If you make changes on this screen after you have performed checks on the installation media you will need to reperform those checks"
            
        }
        else {
            $WPF_PackageSelection_PackageSelection_Label.Text = "You have made changes to the packages and/or icons. You will need to reperform the check for install media."
        }
    }

    if ($MainWindowButtons){
        $WPF_Window_Button_LoadSettings.Background = '#FFDDDDDD'
        $WPF_Window_Button_LoadSettings.Foreground = '#FF000000'

        $WPF_Window_Button_SaveSettings.Background = '#FFDDDDDD'
        $WPF_Window_Button_SaveSettings.Foreground = '#FF000000'

        $WPF_Window_Button_PackageSelection.Background = '#FFDDDDDD'
        $WPF_Window_Button_PackageSelection.Foreground = '#FF000000'

        $WPF_Window_Button_SetupDisk.Background = '#FFDDDDDD'
        $WPF_Window_Button_SetupDisk.Foreground = '#FF000000'

        $WPF_Window_Button_StartPage.Background = '#FFDDDDDD'
        $WPF_Window_Button_StartPage.Foreground = '#FF000000'
        
        if ($Script:GUICurrentStatus.CurrentWindow -eq "StartPage"){
            $WPF_Window_Button_StartPage.Background = '#FF017998' 
            $WPF_Window_Button_StartPage.Foreground = '#FFFFFFFF'
        }
        elseif ($Script:GUICurrentStatus.CurrentWindow -eq 'PackageSelection'){
            $WPF_Window_Button_PackageSelection.Background = '#FF017998' 
            $WPF_Window_Button_PackageSelection.Foreground = '#FFFFFFFF'
        }
        elseif ($Script:GUICurrentStatus.CurrentWindow -eq 'DiskPartition'){
            $WPF_Window_Button_SetupDisk.Background = '#FF017998' 
            $WPF_Window_Button_SetupDisk.Foreground = '#FFFFFFFF'
        }
       
    }

    if (($CheckforRunningImage) -or ($PackageSelectionWindow) -or ($DiskPartitionWindow)){
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

            $AmigaDriveDetailsToTest  = [System.Collections.Generic.List[PSCustomObject]]::New()
            
            $SystemDeviceName = (Get-InputCSVs -Diskdefaults | Where-Object {$_.Disk -eq 'System'}).DeviceName
            $DefaultID76Partition = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | Where-Object {$_.Partition.defaultgptmbrpartition -eq $true -and $_.Partition.PartitionSubType -eq 'ID76'}
           
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

                $TopPriorityonDefaultDrive = $AmigaDriveDetailsToTest | Where-Object {$_.Disk -eq $DefaultID76Partition.PartitionName} | Sort-Object 'Priority'| Select-Object -first 1
                
                if ($Script:GUIActions.InstallOSFiles -eq $true){

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

    if ($Emu68Settings){
        if ($Script:GUIActions.InstallOSFiles -eq $true){
            $WPF_StartPage_OSSelection_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SourceFiles_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button_Check.Visibility = 'Visible'
            $WPF_StartPage_ADFPath_Label.Visibility = 'Visible'
            $WPF_StartPage_Settings_GroupBox.Visibility = 'Visible'
        }
        elseif ($Script:GUIActions.InstallOSFiles -eq $false){
            $WPF_StartPage_OSSelection_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SourceFiles_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button.Visibility = 'Hidden'
            $WPF_StartPage_ADFpath_Button_Check.Visibility = 'Hidden'
            $WPF_StartPage_ADFPath_Label.Visibility = 'Hidden'
            $WPF_StartPage_Settings_GroupBox.Visibility = 'Visible'
        }
        if ($Script:GUIActions.ROMLocation){
            $WPF_StartPage_RomPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate $Script:GUIActions.ROMLocation
            $WPF_StartPage_RomPath_Button.Background = 'Green'
            $WPF_StartPage_RomPath_Button.Foreground = 'White'
        }
        else {
            $WPF_StartPage_RomPath_Label.Text = 'Using default Kickstart folder'
            $WPF_StartPage_RomPath_Button.Foreground = 'Black'
            $WPF_StartPage_RomPath_Button.Background = '#FFDDDDDD'
        }
        if ($Script:GUIActions.InstallMediaLocation){
            $WPF_StartPage_ADFPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate $Script:GUIActions.InstallMediaLocation
            $WPF_StartPage_ADFPath_Button.Background = 'Green'
            $WPF_StartPage_ADFPath_Button.Foreground = 'White'

        }
        else {           
            $WPF_StartPage_ADFPath_Label.Text = 'Using default install media folder'
            $WPF_StartPage_ADFPath_Button.Foreground = 'Black'
            $WPF_StartPage_ADFPath_Button.Background = '#FFDDDDDD'       
        }

        if ($Script:GUIActions.FoundKickstarttoUse){
            $WPF_StartPage_ROMpath_Button_Check.Background = 'Green'
            $WPF_StartPage_ROMpath_Button_Check.Foreground = 'White'
        }
        else{
            $WPF_StartPage_Rompath_Button_Check.Background = '#FFDDDDDD'
            $WPF_StartPage_Rompath_Button_Check.Foreground = 'Black'
        }
        
        if ($Script:GUIActions.FoundInstallMediatoUse){
            $WPF_StartPage_ADFpath_Button_Check.Background = 'Green'
            $WPF_StartPage_ADFpath_Button_Check.Foreground = 'White'
        }
        else{
            $WPF_StartPage_ADFpath_Button_Check.Background = '#FFDDDDDD'
            $WPF_StartPage_ADFpath_Button_Check.Foreground = 'Black'
        }

        if (($Script:GUIActions.SSID) -and (-not ($WPF_StartPage_SSID_Textbox.Text))){
            $WPF_StartPage_SSID_Textbox.Text = $Script:GUIActions.SSID 
        }
        if (($Script:GUIActions.WifiPassword) -and (-not ($WPF_StartPage_Password_Textbox.Text))){
            $WPF_StartPage_Password_Textbox.Text = $Script:GUIActions.WifiPassword 
        }
        
        if (($Script:GUIActions.ScreenModetoUseFriendlyName) -and (-not ($WPF_StartPage_ScreenMode_Dropdown.SelectedItem))) {
           $WPF_StartPage_ScreenMode_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseFriendlyName
        }
    }

    #  $WPF_DP_Partition_MBR_2.Children[0].Name
    #  $WPF_DP_Partition_MBR_2.Children[1].Name
    #  $WPF_DP_Partition_MBR_2.Children[2].Name
    #  $WPF_DP_Partition_MBR_2.Children[3].Name
    #  $WPF_DP_Partition_MBR_2.Children[4].Name

    # $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1.Children[0].Name
    # $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1.Children[1].Name
    # $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1.Children[2].Name
    # $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1.Children[3].Name
    # $WPF_DP_Partition_MBR_2_AmigaDisk_Partition_1.Children[4].Name


    if ($HighlightSelectedPartitions){
        if ($Script:GUIActions.DiskSizeSelected){
            ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries + $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries) | ForEach-Object {
                if (($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName -eq $_.PartitionName) -or ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName -eq $_.PartitionName)){
                    $_.Partition.Children[0].Stroke='Red'   
                    $_.Partition.Children[1].Stroke='Red'  
                    $_.Partition.Children[2].Stroke='Red'  
                    $_.Partition.Children[3].Stroke='Red'                   
                }
                else {
                    $_.Partition.Children[0].Stroke='Black'  
                    $_.Partition.Children[1].Stroke='Black'  
                    $_.Partition.Children[2].Stroke='Black'  
                    $_.Partition.Children[3].Stroke='Black'  
                }
                
            }
    
            if ($Script:GUICurrentStatus.SelectedGPTMBRPartition){
                $MBRPartitionCounter = 1
                $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | ForEach-Object {
                    If ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName -eq $_.PartitionName){
                        $WPF_DP_SelectedMBRPartition_Value.text = "Partition #$MBRPartitionCounter"
                    }
                    $MBRPartitionCounter ++
                }

                $WPF_DP_MBRGPTSettings_GroupBox.Visibility = 'Visible'
                If ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSubType -eq 'ID76'){ 
                    $AmigaDiskName = "$($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName)_AmigaDisk"
                    if (Get-Variable -name $AmigaDiskName){
                        Set-AmigaDiskSizeOverhangPixels -AmigaDiskName $AmigaDiskName
                    }
                    #$WPF_DP_DiskGrid_Amiga.Visibility ='Visible'
                    $WPF_DP_Amiga_GroupBox.Visibility = 'Visible'
                    $AmigaDiskSizeBytes = [int64](Get-Variable -name  $AmigaDiskName).value.DiskSizeBytes
                    $AmigaEndofPartitionsBytes = [int64](Get-GUIPartitionStartEnd -PartitionType 'Amiga' -AmigaDiskName $AmigaDiskName).EndingPositionBytes
                    $FreeSpacetoCheck = $AmigaDiskSizeBytes -$AmigaEndofPartitionsBytes              
                    $DiskSize = (Get-ConvertedSize -Size $AmigaDiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2) 
                    $DiskFreeSpaceSize = (Get-ConvertedSize -Size $FreeSpacetoCheck -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)  
                    #Write-debug "$($DiskSize.Size) $($DiskSize.Scale) $($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)"
                    $WPF_DP_Amiga_TotalDiskSize.Text = "$($DiskSize.Size) $($DiskSize.Scale)"
                    $WPF_DP_Amiga_TotalFreeSpaceSize.Text = "$($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)"                    
                    $WPF_DP_Amiga_TotalDiskSize_Label.Visibility = 'Visible'
                    $WPF_DP_Amiga_TotalDiskSize.Visibility = 'Visible'
                    $WPF_DP_Amiga_TotalFreeSpaceSize.Visibility = 'Visible'
                    $WPF_DP_Amiga_TotalFreeSpaceSize_Label.Visibility = 'Visible'
                    $WPF_DP_AmigaSettings_GroupBox.Visibility = 'Visible'
                    $TotalChildren = $WPF_DP_DiskGrid_Amiga.Children.Count-1
                    for ($i = 0; $i -le $TotalChildren; $i++) {
                        $WPF_DP_DiskGrid_Amiga.Children.Remove($WPF_DP_DiskGrid_Amiga.Children[$i])
                    }
                    $WPF_DP_DiskGrid_Amiga.AddChild(((Get-Variable -Name ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName+'_AmigaDisk')).value))
                    if (-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)){
                        $WPF_DP_DiskGrid_Amiga.UpdateLayout()
                        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)                               
                    }                    
                }
                else{
                    #$WPF_DP_DiskGrid_Amiga.Visibility = 'Hidden'
                    $WPF_DP_Amiga_GroupBox.Visibility = 'Hidden'
                    $WPF_DP_Amiga_TotalDiskSize_Label.Visibility = 'Hidden'
                    $WPF_DP_Amiga_TotalDiskSize.Visibility = 'Hidden'
                    $WPF_DP_Amiga_TotalFreeSpaceSize.Visibility = 'Hidden'
                    $WPF_DP_Amiga_TotalFreeSpaceSize_Label.Visibility = 'Hidden'

                }
                $WPF_DP_GPTMBR_GroupBox.Visibility = 'Visible'
              
            }
            else{
                $WPF_DP_SelectedMBRPartition_Value.text = "No partition selected"
               # $WPF_DP_DiskGrid_Amiga.Visibility = 'Hidden'
                $WPF_DP_Amiga_GroupBox.Visibility = 'Hidden'
                $WPF_DP_Amiga_TotalDiskSize_Label.Visibility = 'Hidden'
                $WPF_DP_Amiga_TotalDiskSize.Visibility = 'Hidden'
                $WPF_DP_Amiga_TotalFreeSpaceSize.Visibility = 'Hidden'
                $WPF_DP_Amiga_TotalFreeSpaceSize_Label.Visibility = 'Hidden'                                
                $WPF_DP_MBRGPTSettings_GroupBox.Visibility = 'Hidden'
                $WPF_DP_AmigaSettings_GroupBox.Visibility = 'Hidden'
                #$WPF_DP_GPTMBR_GroupBox.Visibility = 'Hidden'
            }
            if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                $WPF_DP_AmigaSettings_GroupBox.Visibility = 'Visible'
            }
        }
        else {
            $WPF_DP_GPTMBR_GroupBox.Visibility = 'Hidden'
            $WPF_DP_Amiga_GroupBox.Visibility = 'Hidden'
            $WPF_DP_Amiga_TotalDiskSize_Label.Visibility = 'Hidden'
            $WPF_DP_Amiga_TotalDiskSize.Visibility = 'Hidden'
            $WPF_DP_Amiga_TotalFreeSpaceSize.Visibility = 'Hidden'
            $WPF_DP_Amiga_TotalFreeSpaceSize_Label.Visibility = 'Hidden'
            $WPF_DP_MBRGPTSettings_GroupBox.Visibility = 'Hidden'
            $WPF_DP_AmigaSettings_GroupBox.Visibility = 'Hidden'            
        }
   
    }
    
    if (($DiskPartitionWindow) -or ($PhysicalvsImage)){
        if ($Script:GUIActions.OutputType -eq 'Image'){
            $WPF_DP_DiskSizeImage_GroupBox.Visibility = 'Visible'
            $WPF_DP_DiskSizePhysicalDisk_GroupBox.Visibility = 'Hidden'

        }
        elseif ($Script:GUIActions.OutputType -eq 'Disk'){
            $WPF_DP_DiskSizeImage_GroupBox.Visibility = 'Hidden'
            $WPF_DP_DiskSizePhysicalDisk_GroupBox.Visibility = 'Visible'
        }
        else {
            $WPF_DP_DiskSizeImage_GroupBox.Visibility = 'Hidden'
            $WPF_DP_DiskSizePhysicalDisk_GroupBox.Visibility = 'Hidden'
        }

    }

    if (($DiskPartitionWindow) -or ($UpdateInputBoxes)){
        if ($Script:GUICurrentStatus.SelectedGPTMBRPartition){
            if (-not $WPF_DP_SelectedSize_Input.InputEntry -eq $true){
                $SizetoReturn =  (Get-ConvertedSize -Size $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
                $WPF_DP_SelectedSize_Input.Background = 'White'
                $WPF_DP_SelectedSize_Input.Text = $SizetoReturn.Size
                $WPF_DP_SelectedSize_Input_SizeScale_Dropdown.SelectedItem = $SizetoReturn.Scale
            }
           
            $PartitionsToCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries 
                       
            $PartitionToCheck = $PartitionsToCheck | Where-Object {$_.PartitionName -eq $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName}
            $SpaceatBeginning = (Get-ConvertedSize -Size $PartitionToCheck.BytesAvailableLeft -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $SpaceatEnd = (Get-ConvertedSize -Size $PartitionToCheck.BytesAvailableRight -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $DiskSize = (Get-ConvertedSize -Size $WPF_DP_Disk_GPTMBR.DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $DiskFreeSpaceSize = (Get-ConvertedSize -Size (($PartitionsToCheck[$PartitionsToCheck.Count-1]).BytesAvailableRight) -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            
            $WPF_DP_SpaceatBeginning_Input.Background = 'White'
            $WPF_DP_SpaceatBeginning_Input.Text = $SpaceatBeginning.Size
            $WPF_DP_SpaceatBeginning_Input_SizeScale_Dropdown.SelectedItem  = $SpaceatBeginning.Scale
            $WPF_DP_SpaceatEnd_Input.Background = 'White'
            $WPF_DP_SpaceatEnd_Input.Text =  $SpaceatEnd.Size
            $WPF_DP_SpaceatEnd_Input_SizeScale_Dropdown.SelectedItem = $SpaceatEnd.Scale         
            $WPF_DP_MBR_TotalDiskSize.Text = "$($DiskSize.Size) $($DiskSize.Scale)"
            $WPF_DP_MBR_TotalFreeSpaceSize.Text = "$($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)" 

            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition -TextBoxControl $WPF_DP_MBR_VolumeName_Input -Value 'VolumeName' -CanChangeParameter 'CanRenameVolume'

        }
        else {
            if ($WPF_DP_GPTMBR_GroupBox.Visibility -eq 'Visible'){                
                $DiskSize = (Get-ConvertedSize -Size $WPF_DP_Disk_GPTMBR.DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
                $PartitionsToCheck = $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries 
                $DiskFreeSpaceSize = (Get-ConvertedSize -Size (($PartitionsToCheck[$PartitionsToCheck.Count-1]).BytesAvailableRight) -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
                $WPF_DP_SpaceatBeginning_Input.Background = 'White'
                $WPF_DP_SpaceatBeginning_Input.Text =''
                $WPF_DP_SpaceatBeginning_Input_SizeScale_Dropdown.SelectedItem  = ''
                $WPF_DP_SpaceatEnd_Input.Background = 'White'
                $WPF_DP_SpaceatEnd_Input.Text = ''
                $WPF_DP_SpaceatEnd_Input_SizeScale_Dropdown.SelectedItem =''
                $WPF_DP_SelectedSize_Input.Background = 'White' 
                $WPF_DP_SelectedSize_Input.Text = ''
                $WPF_DP_SelectedSize_Input_SizeScale_Dropdown.SelectedItem = ''
                $WPF_DP_MBR_TotalDiskSize.Text = "$($DiskSize.Size) $($DiskSize.Scale)"
                $WPF_DP_MBR_TotalFreeSpaceSize.Text = "$($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)"   
                If ($Script:GUICurrentStatus.OperationMode -eq "Simple"){
                       $WPF_DP_MBRPartitionSelect_LeftArrow.Visibility = "Hidden"
                       $WPF_DP_MBRPartitionSelect_RightArrow.Visibility = "Hidden"
                       $WPF_DP_Button_DeleteMBRPartition.Visibility = "Hidden"
                       $WPF_DP_Button_RemoveFreeSpace.Visibility = "Hidden"
                       $WPF_DP_Button_AddNewGPTMBRPartition.Visibility = "Hidden"
                       $WPF_DP_AddNewGPTMBRPartition_DropDown.Visibility = "Hidden"
                       $WPF_DP_AddNewGPTMBRPartition_Type_DropDown.Visibility = "Hidden"
                       $WPF_DP_SelectedMBRPartition_Label.Visibility = "Hidden"
                       $WPF_DP_SelectedMBRPartition_Value.Visibility = "Hidden"
                       $WPF_DP_MBRPartitionSelect_Label.Visibility = "Hidden"
                       $WPF_DP_Amiga_GroupBox.Visibility = "Visible"
                       $WPF_DP_DiskGrid_Amiga.Visibility = "Visible"
                       $WPF_DP_SelectedAmigaPartition_Label.Visibility = "Hidden"
                       $WPF_DP_SelectedAmigaPartition_Value.Visibility = "Hidden"
                       $WPF_DP_AmigaPartitionSelect_Label.Visibility = "Hidden"
                       $WPF_DP_AmigaPartitionSelect_LeftArrow.Visibility = "Hidden"
                       $WPF_DP_AmigaPartitionSelect_RightArrow.Visibility = "Hidden"
                       $WPF_DP_Button_AmigaRemoveFreeSpace.Visibility = "Hidden"
                       $WPF_DP_Button_DeleteAmigaPartition.Visibility = "Hidden"
                       $WPF_DP_AddNewAmigaPartition_DropDown.Visibility = "Hidden"
                       $WPF_DP_Button_AddNewAmigaPartition.Visibility = "Hidden"
                       $WPF_DP_Button_ImportFilesCancel.Visibility = "Hidden"
                       $WPF_DP_Button_ImportFiles.Visibility = "Hidden"
                       $WPF_DP_Button_ImportFiles_Label.Visibility = "Hidden"
                       $WPF_DP_ImportFilesSize_Value.Visibility = "Hidden"
                       
                       $WPF_DP_SimpleMode_FAT32Size_Label.Visibility = "Visible"
                       $WPF_DP_SimpleMode_FAT32Size_Value.Visibility = "Visible"
                       $WPF_DP_SimpleMode_ID76Size_Label.Visibility = "Visible"
                       $WPF_DP_SimpleMode_ID76Size_Value.Visibility = "Visible"
                       $WPF_DP_SimpleMode_Legend_FAT32SizeDefault.Visibility = "Visible"
                       #$WPF_DP_SimpleMode_Legend_ID76Size.Visibility = "Visible"
                       $WPF_DP_SimpleMode_Legend_WorkbenchSizeDefault.Visibility = "Visible"
                       $WPF_DP_SimpleMode_Legend_WorkSize.Visibility = "Visible"
                       $WPF_DP_SimpleMode_WorkbenchSize_Label.Visibility = "Visible"
                       $WPF_DP_SimpleMode_WorkbenchSize_Value.Visibility = "Visible"
                       $WPF_DP_SimpleMode_WorkSize_Label.Visibility = "Visible"
                       $WPF_DP_SimpleMode_WorkSize_Value.Visibility = "Visible"
                       
                       $FAT32Partition = (Get-Variable -Name "*_Partition_MBR_*" -Exclude "*Amiga*" | Where-Object {$_.Value.PartitionSubType -eq "FAT32"}).value
                       $FAT32PartitionSize = Get-ConvertedSize -Size $FAT32Partition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2
                       $WPF_DP_SimpleMode_FAT32Size_Value.Text = "$($FAT32PartitionSize.size) $($FAT32PartitionSize.scale)"

                       $ID76Partition = (Get-Variable -Name "*_Partition_MBR_*" -Exclude "*Amiga*" | Where-Object {$_.Value.PartitionSubType -eq "ID76"}).Value
                       $ID76PartitionSize = Get-ConvertedSize -Size $ID76Partition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2
                       $WPF_DP_SimpleMode_ID76Size_Value.Text = "$($ID76PartitionSize.size) $($ID76PartitionSize.scale)"

                       $WorkbenchPartition = (Get-Variable -Name "$($ID76Partition.PartitionName)_AmigaDisk_*" | Where-Object {$_.Value.VolumeName -eq "Workbench"}).value
                       $WorkbenchPartitionSize = Get-ConvertedSize -Size $WorkbenchPartition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2
                       $WPF_DP_SimpleMode_WorkbenchSize_Value.Text = "$($WorkbenchPartitionSize.size) $($WorkbenchPartitionSize.scale)"

                       if ((Get-Variable -Name "$($ID76Partition.PartitionName)_AmigaDisk_*").count -ne 2){
                           $WPF_DP_SimpleMode_WorkSize_Value.Text = "N/A (Multiple Work Partitions)"
                       }
                       else {
                           $WorkPartition = (Get-Variable -Name "$($ID76Partition.PartitionName)_AmigaDisk_*" | Where-Object {$_.Value.VolumeName -eq "Work"}).value
                           $WorkPartitionSize = Get-ConvertedSize -Size $WorkPartition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2
                           $WPF_DP_SimpleMode_WorkSize_Value.Text = "$($WorkPartitionSize.size) $($WorkPartitionSize.scale)"
                       }
                       $AmigaDiskName =  (Get-Variable -Name "*_AmigaDisk").Name
                       $AmigaDiskSizeBytes = [int64](Get-Variable -name  $AmigaDiskName).value.DiskSizeBytes
                       $AmigaEndofPartitionsBytes = [int64](Get-GUIPartitionStartEnd -PartitionType 'Amiga' -AmigaDiskName $AmigaDiskName).EndingPositionBytes
                       $FreeSpacetoCheck = $AmigaDiskSizeBytes -$AmigaEndofPartitionsBytes              
                       $DiskSize = (Get-ConvertedSize -Size $AmigaDiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2) 
                       $DiskFreeSpaceSize = (Get-ConvertedSize -Size $FreeSpacetoCheck -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2) 
                       $WPF_DP_Amiga_TotalDiskSize.Text = "$($DiskSize.Size) $($DiskSize.Scale)"
                       $WPF_DP_Amiga_TotalFreeSpaceSize.Text = "$($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)"    
                       $WPF_DP_Amiga_TotalFreeSpaceSize.Visibility = 'Visible' 
                       $WPF_DP_Amiga_TotalFreeSpaceSize_Label.Visibility = 'Visible'
                        
                       $WPF_DP_Amiga_TotalDiskSize_Label.Visibility = 'Visible'
                       $WPF_DP_Amiga_TotalDiskSize.Visibility = 'Visible'
                       $TotalChildren = $WPF_DP_DiskGrid_Amiga.Children.Count-1
                       for ($i = 0; $i -le $TotalChildren; $i++) {
                           $WPF_DP_DiskGrid_Amiga.Children.Remove($WPF_DP_DiskGrid_Amiga.Children[$i])
                        }
                        $WPF_DP_DiskGrid_Amiga.AddChild((Get-Variable -Name $AmigaDiskName).value)                                             
                       
                }
                   
            }
        }
        if ($Script:GUICurrentStatus.SelectedAmigaPartition){
                $RDBPartitionCounter = 1
                $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName} | ForEach-Object {
                    If ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName -eq $_.PartitionName){
                        $WPF_DP_SelectedAmigaPartition_Value.text = "Partition #$RDBPartitionCounter"
                    }
                    $RDBPartitionCounter ++
                }
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.ImportedFilesPath){
                $SpaceImportedFilesConverted = (Get-ConvertedSize -Size $Script:GUICurrentStatus.SelectedAmigaPartition.ImportedFilesSpaceBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
                $WPF_DP_Button_ImportFiles.Background = 'Green'
                $WPF_DP_Button_ImportFiles.Foreground = 'White'
                $WPF_DP_Button_ImportFiles_Label.Text = Get-FormattedPathforGUI -PathtoTruncate $Script:GUICurrentStatus.SelectedAmigaPartition.ImportedFilesPath -Length 15
                $WPF_DP_ImportFilesSize_Label.Visibility = 'Visible'
                $WPF_DP_ImportFilesSize_Value.Visibility = 'Visible'
                $WPF_DP_ImportFilesSize_Value.Text = "$($SpaceImportedFilesConverted.Size) $($SpaceImportedFilesConverted.Scale)"
            }
            else {
                $WPF_DP_Button_ImportFiles_Label.Text = 'No imported folder selected'
                $WPF_DP_Button_ImportFiles.Background = "#FFDDDDDD"
                $WPF_DP_Button_ImportFiles.Foreground = 'Black'
                $WPF_DP_ImportFilesSize_Label.Visibility = 'Hidden'
                $WPF_DP_ImportFilesSize_Value.Visibility = 'Hidden'
                $WPF_DP_ImportFilesSize_Value.Text = ''
            }

            if (-not $WPF_DP_Amiga_SelectedSize_Input.InputEntry -eq $true){
                $SizetoReturn =  (Get-ConvertedSize -Size $Script:GUICurrentStatus.SelectedAmigaPartition.PartitionSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
                $WPF_DP_Amiga_SelectedSize_Input.Background = 'White'
                $WPF_DP_Amiga_SelectedSize_Input.Text = $SizetoReturn.Size
                $WPF_DP_Amiga_SelectedSize_Input_SizeScale_Dropdown.SelectedItem = $SizetoReturn.Scale
            }

            $PartitionsToCheck = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName}

            $PartitionToCheck = $PartitionsToCheck | Where-Object {$_.PartitionName -eq $Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName}
            $SpaceatBeginning = (Get-ConvertedSize -Size $PartitionToCheck.BytesAvailableLeft -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $SpaceatEnd = (Get-ConvertedSize -Size $PartitionToCheck.BytesAvailableRight -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $DiskSize = (Get-ConvertedSize -Size ((Get-Variable -name ($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.Substring(0,($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName.IndexOf('AmigaDisk_Partition_')+9)))).value).DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            $DiskFreeSpaceSize = (Get-ConvertedSize -Size (($PartitionsToCheck[$PartitionsToCheck.Count-1]).BytesAvailableRight) -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
            
            $WPF_DP_Amiga_SpaceatBeginning_Input.Background = 'White'
            $WPF_DP_Amiga_SpaceatBeginning_Input.Text = $SpaceatBeginning.Size
            $WPF_DP_Amiga_SpaceatBeginning_Input_SizeScale_Dropdown.SelectedItem  = $SpaceatBeginning.Scale
            $WPF_DP_Amiga_SpaceatEnd_Input.Background = 'White'
            $WPF_DP_Amiga_SpaceatEnd_Input.Text =  $SpaceatEnd.Size
            $WPF_DP_Amiga_TotalDiskSize.Text = "$($DiskSize.Size) $($DiskSize.Scale)"
            $WPF_DP_Amiga_TotalFreeSpaceSize.Text = "$($DiskFreeSpaceSize.Size) $($DiskFreeSpaceSize.Scale)"
            
            $WPF_DP_Amiga_SpaceatEnd_Input_SizeScale_Dropdown.SelectedItem = $SpaceatEnd.Scale
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.Bootable -eq $true){
                # Write-debug "Bootable is true for partition $($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName)"
                $WPF_DP_Amiga_Bootable.IsChecked = 'True'
            }
            elseif ($Script:GUICurrentStatus.SelectedAmigaPartition.Bootable -eq $false){
                # Write-debug "Bootable is false for partition $($Script:GUICurrentStatus.SelectedAmigaPartition.PartitionName)"
                $WPF_DP_Amiga_Bootable.IsChecked = ''
            }
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.NoMount -eq $true){
                # Write-debug "NoMount is true for partition $($Script:GUICurrentStatus.SelectedAmigaPartition)"
                $WPF_DP_Amiga_Mountable.IsChecked = ''
            }
            elseif ($Script:GUICurrentStatus.SelectedAmigaPartition.NoMount -eq $false){
                # Write-debug "NoMount is false for partition $($Script:GUICurrentStatus.SelectedAmigaPartition)"
                $WPF_DP_Amiga_Mountable.IsChecked = 'True'
            }
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.CanChangeMountable -eq $true){
                $WPF_DP_Amiga_Mountable.IsEnabled = 'True'
            }
            else {
                $WPF_DP_Amiga_Mountable.IsEnabled = ''
            }            
            if ($Script:GUICurrentStatus.SelectedAmigaPartition.CanChangeBootable -eq $true){
                $WPF_DP_Amiga_Bootable.IsEnabled = 'True'
            }
            else {
                $WPF_DP_Amiga_Bootable.IsEnabled = ''
            }

            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Buffers_Input -Value 'buffers' -CanChangeParameter 'CanChangeBuffers'      
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DeviceName_Input -Value 'DeviceName' -CanChangeParameter 'CanRenameDevice'
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_VolumeName_Input -Value 'VolumeName' -CanChangeParameter 'CanRenameVolume'
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_MaxTransfer_Input -Value 'MaxTransfer' -CanChangeParameter 'CanChangeMaxTransfer'
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Priority_Input -Value 'Priority' -CanChangeParameter 'CanChangePriority'
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Buffers_Input -Value 'buffers' -CanChangeParameter 'CanChangeBuffers'
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_DosType_Input -Value 'DosType' -CanChangeParameter 'CanChangeDosType'  
            Update-UITextbox -Partition $Script:GUICurrentStatus.SelectedAmigaPartition -TextBoxControl $WPF_DP_Amiga_Mask_Input -Value 'Mask' -CanChangeParameter 'CanChangeMask'  

        }    
        else {
            $WPF_DP_SelectedAmigaPartition_Value.text = "No partition selected"
            $WPF_DP_ImportFilesSize_Label.Visibility = 'Hidden'
            $WPF_DP_ImportFilesSize_Value.Visibility = 'Hidden'
            $WPF_DP_ImportFilesSize_Value.Text = ''                            
            if ($WPF_DP_Amiga_GroupBox.Visibility -eq 'Visible'){
                $WPF_DP_Amiga_SpaceatBeginning_Input.Background = 'White'
                $WPF_DP_Amiga_SpaceatBeginning_Input.Text =''
                $WPF_DP_Amiga_SpaceatBeginning_Input_SizeScale_Dropdown.SelectedItem  = ''
                $WPF_DP_Amiga_SpaceatEnd_Input.Background = 'White'
                $WPF_DP_Amiga_SpaceatEnd_Input.Text = ''
                $WPF_DP_Amiga_SpaceatEnd_Input_SizeScale_Dropdown.SelectedItem =''
                $WPF_DP_Amiga_SelectedSize_Input.Background = 'White' 
                $WPF_DP_Amiga_SelectedSize_Input.Text = ''
                $WPF_DP_Amiga_SelectedSize_Input_SizeScale_Dropdown.SelectedItem = ''
                #$WPF_DP_Amiga_TotalDiskSize.Text = ''
                #$WPF_DP_Amiga_TotalFreeSpaceSize.Text = ''             
            }
        }    
    }

    if (($DiskPartitionWindow) -or ($Buttons)){
        if ($Script:GUIActions.OutputPath){
            $WPF_DP_Button_SaveImage.Background = 'Green'
            $WPF_DP_Button_SaveImage.Foreground = 'White'            
            $WPF_DP_Button_SaveImage_Label.Text =  Get-FormattedPathforGUI -PathtoTruncate $Script:GUIActions.OutputPath -Length 25
        }
        else{
            $WPF_DP_Button_SaveImage.Background = '#FFDDDDDD'
            $WPF_DP_Button_SaveImage.Foreground = "Black" 
            $WPF_DP_Button_SaveImage_Label.Text =  "No location selected"                   
        }

        if (($Script:GUIActions.OutputType -eq "Image") -and ($Script:GUIActions.ImageSizeSelected -eq $true)){
                $WPF_DP_Button_SetImageSize.Background = 'Green'
                $WPF_DP_Button_SetImageSize.Foreground = 'White'  
                $WPF_DP_Button_SetImageSize_Label.Text = "$((Get-ConvertedSize -Size $Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2).size) $((Get-ConvertedSize -Size $Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2).scale)"                
            }
            else {
                $WPF_DP_Button_SetImageSize.Background = '#FFDDDDDD'
                $WPF_DP_Button_SetImageSize.Foreground = "Black"       
                $WPF_DP_Button_SetImageSize_Label.Text = ""                      
            }
    }

    If ($FreeSpaceAlert){
        $FreeSpaceBytes_MBR = 0
        $FreeSpaceBytes_Amiga = 0
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries | ForEach-Object {
            $FreeSpaceBytes_MBR += $_.BytesAvailableLeft
        }
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries | ForEach-Object {
            $FreeSpaceBytes_Amiga += $_.BytesAvailableLeft               
        }

        If ($FreeSpaceBytes_MBR -eq 0){
            # Write-debug "No free space - MBR"
            $WPF_DP_MBR_FreeSpaceBetweenPartitions_Label.Visibility = 'hidden'
        }
        else {
            # Write-debug "Free space MBR is:$FreeSpaceBytes_MBR"
            $WPF_DP_MBR_FreeSpaceBetweenPartitions_Label.Visibility = 'visible'
        }
        
        If ($FreeSpaceBytes_Amiga -eq 0){
            # Write-debug "No free space - Amiga"
            $WPF_DP_Amiga_FreeSpaceBetweenPartitions_Label.Visibility = 'hidden'
        }
        else {
            # Write-debug "Free space Amiga is:$FreeSpaceBytes_Amiga"
            $WPF_DP_Amiga_FreeSpaceBetweenPartitions_Label.Visibility = 'visible'
        }

    }   
    
}
