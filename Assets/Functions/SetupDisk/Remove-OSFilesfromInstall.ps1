function Remove-OSFilesfromInstall {
    param (
      
    )
    
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
    $Script:GUIActions.NetworkStack = $null
    $Script:GUIActions.EnableUSBStack = $false
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
    $Script:GUIActions.MUIVersion = $null
    $Script:GUIActions.EnableUSBStack = $null
    $Script:GUIActions.PoseidonVersion = $null
    
}