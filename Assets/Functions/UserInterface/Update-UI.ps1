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
        [Switch]$PackageSelectionWindow,
        [Switch]$WBScreenModeUpdate,
        [Switch]$WBScreenModeChangeType,
        [Switch]$CustomResolution
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
        if ($Script:GUICurrentStatus.OperationMode -eq "Advanced") {
            if ($Script:GUIActions.InstallOSFiles -eq $false) {
                $WPF_Window_Button_PackageSelection.Visibility = 'Hidden'
    
            }
            if ($Script:GUIActions.InstallOSFiles -eq $true) {
                $WPF_Window_Button_PackageSelection.Visibility = 'Visible'
    
            }
            
        }

    }

    if (($CheckforRunningImage) -or ($PackageSelectionWindow) -or ($DiskPartitionWindow) -or ($CustomResolution) ){

        Check-ProcessingImage
    
    }

    if ($Emu68Settings){

        If ($Script:GUIActions.DeleteAllDownloadedFiles -eq $true){
            $WPF_StartPage_DeleteFiles_CheckBox.IsChecked = 1
       
        }
        elseif ($Script:GUIActions.DeleteAllDownloadedFiles -eq $false){
            $WPF_StartPage_DeleteFiles_CheckBox.IsChecked = 0
        }
        
        if ($Script:GUICurrentStatus.RunParallelInstalled -ne "Yes") {
            $WPF_StartPage_RunParallel_CheckBox.IsChecked = 0
            $WPF_StartPage_RunParallel_CheckBox.IsEnabled = 0
        }
        else {
            If ($Script:GUIActions.RunParallel -eq $true){
                $WPF_StartPage_RunParallel_CheckBox.IsChecked = 1
    
            }
            elseif ($Script:GUIActions.RunParallel -eq $false){
                $WPF_StartPage_RunParallel_CheckBox.IsChecked = 0
            }
        }

        if ($Script:GUICurrentStatus.OperationMode -eq "Simple") {
            $WPF_StartPage_SettingsMUIVersion_GroupBox.Visibility = "Hidden"
            $WPF_StartPage_SettingsEmu68Imager_GroupBox.Visibility = "Hidden"
            $WPF_StartPage_Unicam_button.Visibility = "Hidden" 
        }

        Get-InputFileCSV -CSV "Emu68Versions" | ForEach-Object {
            if ($Script:GUIActions.Emu68VersionType -eq $_.Emu68VersionType){
                $WPF_StartPage_Emu68Version_Dropdown.SelectedItem = $_.Emu68VersionTypeFriendlyName
            }
        }
               
        if ($Script:GUIActions.Emu68VersionType -eq 'Release'){
            $WPF_startpage_EnableBupTest_CheckBox.Visibility = 'Visible'
            $WPF_startpage_LowSpeed_CheckBox.Visibility = 'Visible'
            $WPF_startpage_DisableSCSI_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_ForceAgnus_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_ForceAgnus_RadioButtonNTSC.Visibility = 'Hidden'
            $WPF_startpage_ForceAgnus_RadioButtonPAL.Visibility = 'Hidden'
            $WPF_startpage_EnableDMA_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_EnableIRQ_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_OverclockSD_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_OverclockSD_Slider.Visibility = 'Hidden'
            $WPF_startpage_OverclockSD_Value.Visibility = 'Hidden'
            $WPF_startpage_OverclockSD_Value_Text.Visibility = 'Hidden'
            $WPF_startpage_USBStackEnable_CheckBox.Visibility = 'Hidden'
            $WPF_startpage_SettingsPoseidonVersion_GroupBox.Visibility = 'Hidden'

        }
        else {    
            $WPF_startpage_EnableBupTest_CheckBox.Visibility = 'Visible'
            $WPF_startpage_LowSpeed_CheckBox.Visibility = 'Visible'
            $WPF_startpage_DisableSCSI_CheckBox.Visibility = 'Visible'
            $WPF_startpage_ForceAgnus_CheckBox.Visibility = 'Visible'
            $WPF_startpage_ForceAgnus_RadioButtonNTSC.Visibility = 'Visible'
            $WPF_startpage_ForceAgnus_RadioButtonPAL.Visibility = 'Visible'
            $WPF_startpage_EnableDMA_CheckBox.Visibility = 'Visible'
            $WPF_startpage_EnableIRQ_CheckBox.Visibility = 'Visible'
            $WPF_startpage_OverclockSD_CheckBox.Visibility = 'Visible'
            $WPF_startpage_OverclockSD_Slider.Visibility = 'Visible'
            $WPF_startpage_OverclockSD_Value.Visibility = 'Visible'
            $WPF_startpage_USBStackEnable_CheckBox.Visibility = 'Visible'
            $WPF_startpage_SettingsPoseidonVersion_GroupBox.Visibility = 'Hidden'
        }
       
        if ($Script:GUIActions.InstallOSFiles -eq $true){
            $WPF_StartPage_OSSelection_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SourceFiles_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button_Check.Visibility = 'Visible'
            $WPF_StartPage_ADFPath_Label.Visibility = 'Visible'
            $WPF_StartPage_SettingsScreen_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SettingsScreenWB_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SettingsNetworkUSB_GroupBox.Visibility = 'Visible'
        }
        elseif ($Script:GUIActions.InstallOSFiles -eq $false){
            $WPF_StartPage_OSSelection_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SourceFiles_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_ADFpath_Button.Visibility = 'Hidden'
            $WPF_StartPage_ADFpath_Button_Check.Visibility = 'Hidden'
            $WPF_StartPage_ADFPath_Label.Visibility = 'Hidden'
            $WPF_StartPage_SettingsScreen_GroupBox.Visibility = 'Visible'
            $WPF_StartPage_SettingsScreenWB_GroupBox.Visibility = 'Hidden'
            $WPF_StartPage_SettingsNetworkUSB_GroupBox.Visibility = 'Hidden'
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
        
        Get-InputFileCSV -CSV "NetworkStackVersions" | ForEach-Object {
            If ($Script:GUIActions.NetworkStack -eq $_.NetworkStack){
                $WPF_StartPage_NetworkStack_Dropdown.SelectedItem = $_.NetworkStackFriendlyName
            }
        }    
        
        If ($Script:GUIActions.MUIVersion -eq "3.8"){
            $WPF_StartPage_MUIVersion_38.IsChecked = 1

        }
        elseIf ($Script:GUIActions.MUIVersion -eq "5.0"){
            $WPF_StartPage_MUIVersion_50.IsChecked = 1
        }
        
        If ($Script:GUIActions.PoseidonVersion -eq "4.x") {
            $WPF_StartPage_PoseidonVersion_RadioButton45.IsChecked = 1

        }
        elseif ($Script:GUIActions.PoseidonVersion -eq "6.x") {
            $WPF_StartPage_PoseidonVersion_RadioButtonRondoval.IsChecked = 1
        }

        if (($Script:GUIActions.ScreenModetoUseFriendlyName) -and (-not ($WPF_StartPage_ScreenMode_Dropdown.SelectedItem))) {
           $WPF_StartPage_ScreenMode_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseFriendlyName
        }

        if ($Script:GUIActions.ScreenModetoUse -eq "Custom"){
            $WPF_StartPage_CustomScreenMode_button.Visibility = "Visible"
            $WPF_StartPage_CustomScreenMode_button.IsEnabled = 1 
            $CompletenessCheck = Confirm-CustomScreenModeComplete 
            if ($CompletenessCheck -eq "Complete"){
                $WPF_StartPage_CustomScreenMode_button.Background ="Green"
                $WPF_StartPage_CustomScreenMode_button.Foreground = "White"
                $WPF_StartPage_CustomScreenMode_button.Content = "Custom Resolution set"
            }
            else{
                $WPF_StartPage_CustomScreenMode_button.Background ="#FFDDDDDD" 
                $WPF_StartPage_CustomScreenMode_button.Foreground ="#FF000000"
                $WPF_StartPage_CustomScreenMode_button.Content = "Click to set Custom Resolution"
            }
        }
        else{
            $WPF_StartPage_CustomScreenMode_button.Visibility = "Hidden"
            $WPF_StartPage_CustomScreenMode_button.IsEnabled = 0             
        }
        if ($Script:GUIActions.ScreenModetoUseWB){
            if ($Script:GUIActions.ScreenModeType -eq "Native"){
                $WPF_StartPage_WorkbenchColour_Slider.IsEnabled = 1
                $WPF_StartPage_WorkbenchColour_Slider.Maximum = 8
                $WPF_StartPage_Unicam_CheckBox.IsEnabled = 0
                $WPF_StartPage_Unicam_CheckBox.IsChecked = 0                    
            }                
            elseif ($Script:GUIActions.ScreenModeType -eq "RTG"){
                $WPF_StartPage_Unicam_CheckBox.IsEnabled = 1                                                              
                $WPF_StartPage_WorkbenchColour_Slider.IsEnabled = 0
                $WPF_StartPage_WorkbenchColour_Slider.Maximum = 24                
            }
        }

        If ($Script:GUIActions.Emu68VersionType){
            $WPF_StartPage_Emu68Version_Dropdown.SelectedItem = $Script:GUIActions.Emu68VersionType
        }

        if ($Script:GUIActions.EnableBupTest -eq $true){
            $WPF_StartPage_EnableBupTest_CheckBox.IsChecked = 1
        }
        else {
            $WPF_StartPage_EnableBupTest_CheckBox.IsChecked = 0
        }

        if ($Script:GUIActions.SCSIDeviceDisabled -eq $true){
            $WPF_StartPage_DisableSCSI_CheckBox.IsChecked = 1
        }
        else {
            $WPF_StartPage_DisableSCSI_CheckBox.IsChecked = 0
        }
            
        if ($Script:GUIActions.DMAEnabled -eq $true){
            $WPF_StartPage_EnableDMA_CheckBox.IsChecked = 1
            $WPF_StartPage_EnableIRQ_CheckBox.IsEnabled = 0
        }
        else {
            $WPF_StartPage_EnableDMA_CheckBox.IsChecked = 0
            $WPF_StartPage_EnableIRQ_CheckBox.IsEnabled = 1
        }
            
        if ($Script:GUIActions.IRQEnabled -eq $true){
            $WPF_StartPage_EnableIRQ_CheckBox.IsChecked = 1
        }
        else {
            $WPF_StartPage_EnableIRQ_CheckBox.IsChecked = 0
        }   

        if ($Script:GUIActions.AgnusType -eq $null){
            $WPF_StartPage_ForceAgnus_RadioButtonNTSC.Visibility = "Hidden"
            $WPF_StartPage_ForceAgnus_RadioButtonPAL.Visibility = "Hidden"
            $WPF_startpage_ForceAgnus_CheckBox.IsChecked = 0
        }
        else {
            $WPF_startpage_ForceAgnus_CheckBox.IsChecked = 1
            $WPF_StartPage_ForceAgnus_RadioButtonNTSC.Visibility = "Visible"
            $WPF_StartPage_ForceAgnus_RadioButtonPAL.Visibility = "Visible"            
            if ($Script:GUIActions.AgnusType -eq "PAL"){
                $WPF_StartPage_ForceAgnus_RadioButtonPAL.IsChecked = 1

            }
            elseif ($Script:GUIActions.AgnusType -eq "NTSC"){
                $WPF_StartPage_ForceAgnus_RadioButtonNTSC.IsChecked = 1                
            }
        }

        if ($Script:GUIActions.SDLowSpeed -eq $false){
            $WPF_StartPage_LowSpeed_CheckBox.IsChecked = 0
        }

        if ($Script:GUIActions.SDLowSpeed -eq $true){
            $WPF_StartPage_LowSpeed_CheckBox.IsChecked = 1
        }
        
        If (($Script:GUIActions.SDOverClock -eq $false) -or ($Script:GUIActions.SDOverClock -eq $null)) {
            $WPF_StartPage_OverclockSD_CheckBox.IsChecked = 0
            $WPF_StartPage_OverclockSD_Slider.Visibility = "Hidden"
            $WPF_StartPage_OverclockSD_Value.Visibility = "Hidden"
            $WPF_StartPage_OverclockSD_Value_Text.Visibility = "Hidden"
        }

        If ($Script:GUIActions.SDOverClock -eq $true) {
            $WPF_StartPage_OverclockSD_CheckBox.IsChecked = 1
            $WPF_StartPage_OverclockSD_Slider.Visibility = "Visible"
            $WPF_StartPage_OverclockSD_Value.Visibility = "Visible"
            if ($WPF_StartPage_OverclockSD_Slider.Value -gt 50) {
                $WPF_StartPage_OverclockSD_Value.Background = "Red"
                $WPF_StartPage_OverclockSD_Value.Foreground = "White"
                $WPF_StartPage_OverclockSD_Value_Text.Visibility = "Visible"
            }
            else {
                $WPF_StartPage_OverclockSD_Value.Background = "Transparent"
                $WPF_StartPage_OverclockSD_Value.Foreground = "Black"
                $WPF_StartPage_OverclockSD_Value_Text.Visibility = "Hidden"

            }
        }
                 
        If ($Script:GUIActions.EnableUSBStack -eq $true){
            $WPF_startpage_USBStackEnable_CheckBox.IsChecked = 1
            $WPF_startpage_SettingsPoseidonVersion_GroupBox.Visibility = 'Visible'
        }
        else {
            $WPF_startpage_USBStackEnable_CheckBox.IsChecked = 0
            $WPF_startpage_SettingsPoseidonVersion_GroupBox.Visibility = 'Hidden'
        }

        if ($Script:GUIActions.UnicamEnabled -eq $false){
            $WPF_StartPage_Unicam_CheckBox.IsChecked = 0
            $WPF_StartPage_Unicam_button.IsEnabled = 0

        }
        elseif ($Script:GUIActions.UnicamEnabled -eq $true){
            $WPF_StartPage_Unicam_CheckBox.IsChecked = 1
            $WPF_StartPage_Unicam_button.IsEnabled = 1
        }
        if ($Script:GUIActions.WorkbenchBackDropEnabled -eq $true){
            $WPF_StartPage_Backdrop_CheckBox.IsChecked = 1

        }
        else {
            $WPF_StartPage_Backdrop_CheckBox.IsChecked = 0
        }

        if ($Script:GUIActions.ScreenModeType -eq "RTG"){
            $WPF_StartPage_WorkbenchOutput_RadioButtonRTG.IsChecked = 1
        }
         
        elseif ($Script:GUIActions.ScreenModeType -eq "Native"){
            $WPF_StartPage_WorkbenchOutput_RadioButtonNative.IsChecked = 1
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
                    if ((-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)) -or ($Script:GUICurrentStatus.ForceRecheckAmigaPartitionsandBoundaries -eq $true)) {
                        $WPF_DP_DiskGrid_Amiga.UpdateLayout()
                        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)     
                        $Script:GUICurrentStatus.ForceRecheckAmigaPartitionsandBoundaries = $false                          
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
    if ($DiskPartitionWindow){
        Get-InputFileCSV -CSV "DiskTypes" | ForEach-Object {
            if ($Script:GUIActions.DiskType -eq $_.DiskType){
                $WPF_DP_Disk_Type_DropDown.SelectedItem = $_.DiskTypeFriendlyName
            }
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
    
    if (($WBScreenModeUpdate) -or ($WBScreenModeChangeType)) {


        if ($WBScreenModeChangeType){
            if (-not ($Script:GUICurrentStatus.LoadingSettings)){
                $Script:GUIActions.ScreenModetoUseWB = $null
            }
        }

        if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode"){
            $PIScreenModeDetails =  [PSCustomObject]@{
                Width = $Script:GUIActions.CustomScreenMode_Width 
                Height = $Script:GUIActions.CustomScreenMode_Height
                FrameRate = $Script:GUIActions.CustomScreenMode_Framerate
                Aspect = $Script:GUIActions.CustomScreenMode_Aspect
                Margins = $Script:GUIActions.CustomScreenMode_Margins
                Interlace = $Script:GUIActions.CustomScreenMode_Interlace
                rb = $Script:GUIActions.CustomScreenMode_RB 
                Name =  "Custom"
                FriendlyName ="Custom ScreenMode"
                hdmi_group = 2
                hdmi_mode =  87
                hdmi_cvt = "$($Script:GUIActions.CustomScreenMode_Width) $($Script:GUIActions.CustomScreenMode_Height) $($Script:GUIActions.CustomScreenMode_Framerate) $CVTAspectRatio $CVTMargins $CVTInterlace $CVTRB" 
            } 
                       
            $CompletenessCheck = Confirm-CustomScreenModeComplete 
            if ($CompletenessCheck -eq "Complete"){     
                $ValidCustomMode = $true
    
            }
            else {
                $ValidCustomMode = $false
            }
            
        }
        else {
            $PIScreenModeDetails = ($Script:GUIActions.AvailableScreenModes | Where-Object {$_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseFriendlyName})
        }
        
        $isRTG = $Script:GUIActions.ScreenModeType -eq "RTG"

        if ($isRTG){         
            $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
            if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode" -and $ValidCustomMode -eq $false) {
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild("You need to configure the custom screenMode first!")
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = "You need to configure the custom screenMode first!"
                $WPF_StartPage_WorkbenchColour_Label.Visibility = "Hidden"
                $WPF_StartPage_WorkbenchColour_Value.Visibility = "Hidden"
                $WPF_StartPage_ColourDepth_groupBox.Visibility = "Hidden"
                $WPF_StartPage_Unicam_button.Visibility = "Hidden"
                $WPF_StartPage_Unicam_CheckBox.Visibility = "Hidden"                
            }
            else {
                
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
                $WPF_StartPage_WorkbenchColour_Label.Visibility = "Visible"
                $WPF_StartPage_WorkbenchColour_Value.Visibility = "Visible"
                $WPF_StartPage_ColourDepth_groupBox.Visibility = "Visible"
                $WPF_StartPage_Unicam_button.Visibility = "Visible"
                $WPF_StartPage_Unicam_CheckBox.Visibility = "Visible"                     
                
                If ($Script:GUIActions.ScreenModetoUseFriendlyName -eq 'Automatic'){
                    $Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $isRTG} | ForEach-Object {
                        $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                        if (-not $Script:GUIActions.ScreenModetoUseWB){
                            if ($_.DefaultMode -eq $true){
                                $Script:GUIActions.ScreenModetoUseWB = $_.FriendlyName   
                                $Script:GUIActions.ScreenModeWBColourDepth = $_.DefaultDepth
                            }
                        } 
                    }
                    $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB    
                }
                else {
                    $Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $isRTG -and ([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | ForEach-Object {
                        $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                    }
                    if (-not $Script:GUIActions.ScreenModetoUseWB){
                        $WBScreenModeDetails = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $true} | Sort-Object {[int]$_.Height}, {[int]$_.Width}-Descending  | Where-Object {([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | Select-Object -First 1)
                        $Script:GUIActions.ScreenModetoUseWB = $WBScreenModeDetails.FriendlyName    
                        $Script:GUIActions.ScreenModeWBColourDepth = $WBScreenModeDetails.DefaultDepth                                                 
                    }
                    else {
                        $WBScreenModeDetails = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB -and $_.RTG -eq $true})
                         if (([int]$PIScreenModeDetails.Width -lt [int]$WBScreenModeDetails.Width) -or ([int]$PIScreenModeDetails.Height -lt [int]$WBScreenModeDetails.Height)){
                             $Script:GUIActions.ScreenModetoUseWB = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $true} | Sort-Object {[int]$_.Height}, {[int]$_.Width}-Descending  | Where-Object {([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | Select-Object -First 1).FriendlyName
                         }
                    }
                      
                }
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB
                $WPF_StartPage_WorkbenchColour_Slider.Value = $Script:GUIActions.ScreenModeWBColourDepth 
                $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)    
                
            }
        } 
        
        else {
            $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
            if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode" -and $ValidCustomMode -eq $false) {
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild("You need to configure the custom screenMode first!")
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = "You need to configure the custom screenMode first!"
                $WPF_StartPage_WorkbenchColour_Label.Visibility = "Hidden"
                $WPF_StartPage_WorkbenchColour_Value.Visibility = "Hidden"
                $WPF_StartPage_ColourDepth_groupBox.Visibility = "Hidden"
                $WPF_StartPage_Unicam_button.Visibility = "Hidden"
                $WPF_StartPage_Unicam_CheckBox.Visibility = "Hidden"
            }
            else {
                $WPF_StartPage_WorkbenchColour_Label.Visibility = "Visible"
                $WPF_StartPage_WorkbenchColour_Value.Visibility = "Visible"
                $WPF_StartPage_ColourDepth_groupBox.Visibility = "Visible"
                $WPF_StartPage_Unicam_button.Visibility = "Visible"
                $WPF_StartPage_Unicam_CheckBox.Visibility = "Visible"                     

                $Script:GUIActions.AvailableScreenModesWB | Where-Object 'Type' -ne "RTG" | ForEach-Object {
                    $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                    if (-not $Script:GUIActions.ScreenModetoUseWB){
                        if ($_.DefaultMode -eq $true){
                            $Script:GUIActions.ScreenModetoUseWB = $_.FriendlyName   
                            $Script:GUIActions.ScreenModeWBColourDepth = $_.DefaultDepth                        
                        }
                    }
                }
    
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB
                $WPF_StartPage_WorkbenchColour_Slider.Value = $Script:GUIActions.ScreenModeWBColourDepth 
                $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)    
            }           
        }
    }
}
            
        
        
                      





