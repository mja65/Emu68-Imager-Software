$WPF_DP_Button_DeleteMBRPartition.add_click({
        if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }
    # $Script:GUICurrentStatus.SelectedGPTMBRPartition = 'WPF_DP_Partition_MBR_2'
    if ($Script:GUICurrentStatus.SelectedGPTMBRPartition){
        If (($Script:GUIActions.InstallOSFiles -eq $true) -and ($Script:GUICurrentStatus.SelectedGPTMBRPartition.DefaultGPTMBRPartition -eq $true) -and ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSubType -eq 'ID76')){

$MessageBody = 
@"
You have selected the default ID 0x76 Amiga Partition for deletion! If you really want to do this you will not be installing ANY OS files! 

All currently selected Workbench install files, and user selected packages will be unselected. If you change your mind after deleting and want to create an image with an installed OS you will need to you will need to reset the disk (i.e. press the "Reset to Start" button) and reperform those steps. 

Press OK to continue otherwise cancel
"@   

            if ((Show-WarningorError -Msg_Header 'Deleting Default Amiga Partition' -BoxTypeWarning -ButtonType_OKCancel  -Msg_Body $MessageBody) -eq 'Cancel'){
                return
            }
            else {
                $DeleteDefaultAmigaPartition = $true
            }
       
        }

        if ($Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionSubType -eq 'ID76'){
            $DeleteUnderlyingAmigaPartitions = $true
        }
        else {
            $DeleteUnderlyingAmigaPartitions = $false
        }


        $PartitiontoDelete = $Script:GUICurrentStatus.SelectedGPTMBRPartition.PartitionName

        if ((Remove-MBRGUIPartition -Partition $Script:GUICurrentStatus.SelectedGPTMBRPartition) -eq $false){
            Show-WarningorError -Msg_Header 'Cannot Delete Partition' -Msg_Body 'MBR Partition is default partition. Cannot delete.' -BoxTypeError -ButtonType_OK
            return
        }
    
        if ($DeleteUnderlyingAmigaPartitions -eq $true){
            $Script:GUICurrentStatus.SelectedAmigaPartition = $null
            $ListofPartitionstoDelete = ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Where-Object {$_.PartitionName -match $PartitiontoDelete} ).PartitionName
            if ($ListofPartitionstoDelete){
                $ListofPartitionstoDelete  | ForEach-Object {
                    Remove-Variable -Scope Script -Name $_
                }
        
                Remove-Variable -Scope Script -Name  "$($PartitiontoDelete)_AmigaDisk"
            }
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }

        if ($DeleteDefaultAmigaPartition -eq $true){

        $Script:GUIActions.InstallOSFiles = $false
        $Script:GUIActions.InstallMediaLocation = $null
        $Script:GUIActions.OSInstallMediaType = $null
        $Script:GUIActions.FoundInstallMediatoUse = $null
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "TRUE"
        $Script:GUICurrentStatus.PackagesChanged = $null
        $Script:GUIActions.DefaultPackagesSelected = $null 
        $Script:GUIActions.DefaultIconsetSelected = $null
        $Script:GUIActions.SelectedIconSet = $null 
        $Script:GUIActions.AvailablePackages.Clear()
        $Script:GUIActions.AvailableIconSets.Clear()
        $Script:GUIActions.ScreenModeType = $null
        $Script:GUIActions.ScreenModetoUseWB = $null
        $Script:GUIActions.EnableBupTest = $true
        $Script:GUIActions.SCSIDeviceDisabled = $false
        $Script:GUIActions.DMAEnabled = $false
        $Script:GUIActions.IRQEnabled = $false
        $Script:GUIActions.AgnusType = $null
        $Script:GUIActions.SDLowSpeed = $true
        $Script:GUIActions.SDOverClock = $false
        $Script:GUIActions.SDOverClockSpeed = $null
        $Script:GUIActions.UnicamEnabled = $false
                Get-InputFileCSV -CSV "Emu68Versions" | ForEach-Object {
            if ($Script:GUIActions.Emu68VersionType -eq $_.Emu68VersionType){
                $Script:GUIActions.PoseidonVersion = $_.PoseidonVersion
                if ($Script:GUIActions.PoseidonVersion){
                    $Script:GUIActions.EnableUSBStack = $true
                }
                else {
                    $Script:GUIActions.EnableUSBStack = $false
                }
                If ($Script:GUIActions.NetworkStack -notin @($_.NetworkStack -split ',')){
                    $Script:GUIActions.NetworkStack = $_.NetworkStackDefault
                }
            }
        }
        $Script:GUIActions.UnicamEnabled = $false       
        $Script:GUIActions.UnicamDeviceType = $null    
        $Script:GUIActions.UnicamStartonBoot = [bool]$null
        $Script:GUIActions.UnicamScalingType = $null
        $Script:GUIActions.UnicamBParameter = $null
        $Script:GUIActions.UnicamCParameter = $null
        $Script:GUIActions.UnicamPhase = $null
        $Script:GUIActions.UnicamAspectRatio = $null
        $Script:GUIActions.UnicamScanLinesNonLaced = $null
        $Script:GUIActions.UnicamScanLinesLaced = $null  
        $Script:GUIActions.UnicamSizeX = $null
        $Script:GUIActions.UnicamSizeY = $null
        $Script:GUIActions.UnicamOffsetX = $null
        $Script:GUIActions.UnicamOffsetY = $null  
        $Script:GUIActions.WorkbenchBackDropEnabled = $null
        $Script:GUIActions.AvailableScreenModesWB = $null
        $Script:GUIActions.NetworkStack = $null
        $Script:GUIActions.MUIVersion = $null
        $Script:GUIActions.EnableUSBStack = $null

        }

        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null

        Update-UI -DiskPartitionWindow -HighlightSelectedPartitions -Emu68Settings -MainWindowButtons
        
    }
    else {
        Show-WarningorError -Msg_Header 'Cannot Delete Partition' -Msg_Body "No partition is selected!" -BoxTypeError -ButtonType_OK
        return
    }
})
