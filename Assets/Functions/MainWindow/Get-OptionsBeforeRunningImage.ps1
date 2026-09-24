function Get-OptionsBeforeRunningImage {
    param (
       
    )
    
    Remove-Variable -Name 'WPF_RunWindow_*'

    $WPF_RunWindow = Get-XAML -WPFPrefix 'WPF_RunWindow_' -XMLFile '.\Assets\WPF\Window_RunOptions.xaml' -ActionsPath '.\Assets\UIActions\RunWindow\' -AddWPFVariables
    
    If ($Script:GUIActions.ScreenModetoUse -eq "Custom"){
        $CVTAspectRatio = (Get-CVTAspectRatio -AspectRatio $Script:GUIActions.CustomScreenMode_Aspect)
        $CVTMargins = (get-cvtMargins -Margins $Script:GUIActions.CustomScreenMode_Margins)
        $CVTInterlace = (get-cvtInterlace -Interlace $Script:GUIActions.CustomScreenMode_Interlace)
        $CVTRB = (get-cvtBlanking -RB $Script:GUIActions.CustomScreenMode_RB)
        $CVT_String = "$($Script:GUIActions.CustomScreenMode_Width) $($Script:GUIActions.CustomScreenMode_Height) $($Script:GUIActions.CustomScreenMode_Framerate) $CVTAspectRatio $CVTMargins $CVTInterlace $CVTRB" 
    }

    $DiskSizetoReport = (Get-ConvertedSize -Size $WPF_DP_Disk_GPTMBR.DiskSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
    $NumberofMBRPartitions = ($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries).Count
    if ($Script:GUIActions.WifiPassword){
        $WifiPassword = "Password has been set"
    }
    else{
        $WifiPassword = "Not Configured"
    }
    if ($Script:GUIActions.SSID){
        $SSID = $Script:GUIActions.SSID
    }
    else{
        $SSID  = "Not Configured"
    }

    if ($Script:GUIActions.InstallOSFiles -eq $true){
        $InstallType = "Full Install"
    }    
    else {
        $InstallType = "Partition disk and Emu68 install only"
    }
    
    $Script:GUICurrentStatus.RunOptionstoReport.Clear()
    
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Type of Install",$InstallType)

    $NotesText = @()
    
    $Emu68VersionMessage = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $_.Emu68VersionType -eq $Script:GUIActions.Emu68VersionType })).RunImageMessage
    $NetworkStackMessage = ((Get-InputFileCSV -CSV "NetworkStackVersions").where({ $_.NetworkStack -eq $Script:GUIActions.NetworkStack })).RunImageMessage
    $PosedionVersionMessage = ((Get-InputFileCSV -CSV "PoseidonVersions").where({ $_.PoseidonVersion -eq $Script:GUIActions.PoseidonVersion })).RunImageMessage

    If ($Emu68VersionMessage) {
        $NotesText += "$Emu68VersionMessage`r`r"
    }

    if ($NetworkStackMessage){
        $NotesText += "$NetworkStackMessage`r`r"
    }

    If ($PosedionVersionMessage){
        $NotesText += "$PosedionVersionMessage`r`r"
    }

    If ($Script:GUIActions.InstallOSFiles -eq $true){
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("OS to be Installed",$Script:GUIActions.KickstartVersiontoUseFriendlyName)
        $MinimumScreenMode = Check-WBScreenMode
        If ($MinimumScreenMode -eq "RTG"){
            $NotesText += "RTG screenmode chosen. Please ensure you have a monitor connected to the HDMI port on your Raspberry Pi`r`r"
        } 
        elseIf ($MinimumScreenMode -eq "AGA"){
            $NotesText += "AGA screenmode chosen. Please ensure you are running on an Amiga 1200`r`r"

        } 
        elseIf ($MinimumScreenMode -eq "ECS"){
            $NotesText += "ECS screenmode chosen. Please ensure you are running on an Amiga with an ECS Denise (or an Amiga 1200)`r`r"             
        } 
    }

    If ($Script:GUIActions.EnableUSBStack -eq $true){
        $NotesText += "You have enabled USB. The installed driver will only work with either a RaspberryPi4 or a Compute Module 4`r`r"          
    }

    if ($NotesText){
        $WPF_RunWindow_RunOptionsNotes_Value.Text = $NotesText
    } 
    else {
        $WPF_RunWindow_RunOptionsNotes_Value.Visibility = "Hidden"
        $WPF_RunWindow_RunOptionsNotes_Label.Visibility = "Hidden"
        $WPF_RunWindow_RunOptions_Datagrid.Height = 500
    }

    #$null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("--- Overall  ---", "")
    if ($Script:GUIActions.RunParallel -eq $true){
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Download Mode","Parallel") 
    }
    else {
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Download Mode","Sequential")
    }
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Disk or Image",$Script:GUIActions.OutputType)
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Location to be installed",$Script:GUIActions.OutputPath)
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("ScreenMode to Use",$Script:GUIActions.ScreenModetoUseFriendlyName)
    if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode"){
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Custom ScreenMode Parameters:","hdmi_cvt=$CVT_String") 
    }
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Disk Size","$($DiskSizetoReport.Size) $($DiskSizetoReport.Scale) `($($WPF_DP_Disk_GPTMBR.DiskSizeBytes) bytes`)")
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Number of MBR Partitions to Write",$NumberofMBRPartitions)
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Workbench Screen Mode selected (Raspberry Pi):",$Script:GUIActions.ScreenModetoUse)
    $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Emu68 Version to install:",$Script:GUIActions.Emu68VersionType)
    If ($Script:GUIActions.InstallOSFiles -eq $true){
        if ($Script:GUIActions.NetworkStack -eq "Miami - Demo") {
            $Script:GUICurrentStatus.MiamiUserFiles = Check-MiamiUserFiles -MiamiFilesPath ([System.IO.Path]::GetFullPath($Script:Settings.MiamiFilesLocation))      
        }
        if ($Script:GUIActions.NetworkStack -eq "Roadshow - Demo") {
            $Script:GUICurrentStatus.RoadshowUserFiles = Check-RoadshowUserFiles -RoadshowFilesPath ([System.IO.Path]::GetFullPath($Script:Settings.RoadshowFilesLocation))          
        }        
        # $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("--- Network and USB ---", "")
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("MUI Version to install:",$Script:GUIActions.MUIVersion)
        If ($Script:GUIActions.Emu68VersionType -ne "Release"){
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("USB Stack Enabled:",$Script:GUIActions.EnableUSBStack)
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Poseidon Version:",$Script:GUIActions.PoseidonVersion)
        }
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Network TCP/IP Stack:",$Script:GUIActions.NetworkStack)
        if ($Script:GUIActions.NetworkStack -eq "Miami - Demo") {
            if ($Script:GUICurrentStatus.MiamiUserFiles){
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Miami User Files to be Installed:","True")
            }
            else {
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Miami User Files to be Installed:","False")
            }
        }
        elseif ($Script:GUIActions.NetworkStack -eq "Roadshow - Demo"){
            if ($Script:GUICurrentStatus.RoadshowUserFiles){
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Roadshow User Files to be Installed:","True")
            }
            else {
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Roadshow User Files to be Installed:","False")
            }
        }        
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("SSID to configure:",$SSID)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Wifi Password to set:",$WifiPassword)
        #$null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("--- Screen ---", "")
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Screen Mode selected (Workbench):",$Script:GUIActions.ScreenModetoUseWB)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Workbench Backdrop Enabled:",$Script:GUIActions.WorkbenchBackDropEnabled)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Workbench Screen Mode Colour Depth (bits):",$Script:GUIActions.ScreenModeWBColourDepth)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Workbench Screen Mode Type:",$Script:GUIActions.ScreenModeType)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Unicam Enabled (Framethrower):",$Script:GUIActions.UnicamEnabled)
        #$null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("--- Emu68 ---", "")
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Bup Test Enabled on First Boot:",$Script:GUIActions.EnableBupTest)
        $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("SD Low Speed Mode Enabled:",$Script:GUIActions.SDLowSpeed)
        If ($Script:GUIActions.Emu68VersionType -ne "Release"){
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("SD Overclock Enabled:",$Script:GUIActions.SDOverClock)
            If ($Script:GUIActions.SDOverClockEnabled -eq $true){
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("SD Overclock Speed:",$Script:GUIActions.SDOverClockSpeed)
            }
            If ($Script:GUIActions.AgnusType){
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Agnus Type:",$Script:GUIActions.AgnusType)
            }
            else {
                $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Agnus Type:","Not Configured")
            }
            
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("SCSI Device Disabled:",$Script:GUIActions.SCSIDeviceDisabled)
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("DMA Enabled:",$Script:GUIActions.DMAEnabled)
            $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("IRQ Enabled:",$Script:GUIActions.IRQEnabled)             
        }
        #$null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("--- User Files ---", "")

        # if (-not ($Script:GUICurrentStatus.Picasso96UserFiles)) {
        #     $Script:GUICurrentStatus.Picasso96UserFiles = Get-Picasso96UserFiles -Picasso96FilesPath $([System.IO.Path]::GetFullPath($Script:Settings.Picasso96FilesLocation)) -DestinationPath $([System.IO.Path]::GetFullPath("$($Script:Settings.InterimAmigaDrives)\System"))
        # }
        
        # if ($Script:GUICurrentStatus.Picasso96UserFiles){
        #     $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Picasso96 User Files to be Installed:","True")
        # }
        # else {
        #     $null = $Script:GUICurrentStatus.RunOptionstoReport.Rows.Add("Picasso96 User Files to be Installed:","False")
        # }
    }
    
    $WPF_RunWindow_RunOptions_Datagrid.ItemsSource = $Script:GUICurrentStatus.RunOptionstoReport.DefaultView
    
     $WPF_RunWindow.ShowDialog() | out-null
    
#$WPF_RunWindow.Width
# $WPF_RunWindow_RunOptions_Datagrid.Columns

}

 