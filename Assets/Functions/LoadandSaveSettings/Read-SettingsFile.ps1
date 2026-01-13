function Read-SettingsFile {
    param (
        $SettingsFile
    )
    
    
   # $SettingsFile = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Settings\test.e68"

   $Script:GUICurrentStatus.LoadingSettings =$true

   $Script:GUICurrentStatus.HSTCommandstoProcess.ExtractOSFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.CopyIconFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.DiskStructures = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.CopyImportedFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.WriteFilestoDisk = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.CopyImportedFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.HSTCommandstoProcess.AdjustParametersonImportedRDBPartitions = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
   $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
   $Script:GUICurrentStatus.LastMouseMoveUpdateTime = [DateTime]::MinValue
   $Script:GUICurrentStatus.FileBoxOpen = $false
   $Script:GUICurrentStatus.ForceRecheckAmigaPartitionsandBoundaries = $false
   $Script:GUICurrentStatus.ProgressBarMarkers = New-Object System.Collections.ArrayList
   $Script:GUICurrentStatus.NewPartitionDefaultScale = $null
   $Script:GUICurrentStatus.NewPartitionMinimumSizeBytes = $null
   $Script:GUICurrentStatus.NewPartitionMaximumSizeBytes = $null
   $Script:GUICurrentStatus.NewPartitionAcceptedNewValue = $false
   $Script:GUICurrentStatus.ImageSizeAcceptedValue = $null
   $Script:GUICurrentStatus.ImageSizeDefaultScale = $null
   $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $true
   $Script:GUICurrentStatus.RunOptionstoReport = New-Object System.Data.DataTable
   $Script:GUICurrentStatus.IssuesFoundBeforeProcessing = New-Object System.Data.DataTable
   $Script:GUICurrentStatus.ProcessImageStatus = $false
   $Script:GUICurrentStatus.ProcessImageConfirmedbyUser = $false
   $Script:GUICurrentStatus.PathstoRDBPartitions = [System.Collections.Generic.List[PSCustomObject]]::New()
   $Script:GUICurrentStatus.InstallMediaRequiredFromUserSelectablePackages = @()
   $Script:GUICurrentStatus.StartTimeForRunningInstall = $null
   $Script:GUICurrentStatus.EndTimeForRunningInstall  = $null
   $Script:GUICurrentStatus.ImportedPartitionType = $null
   $Script:GUICurrentStatus.SelectedPhysicalDiskforImport = $null
   $Script:GUICurrentStatus.ImportedImagePath = $null
   $Script:GUICurrentStatus.ProcessImportedPartition = $false
   $Script:GUICurrentStatus.TransferSourceLocation  = $null
   $Script:GUICurrentStatus.TransferSourceType = $null
   $Script:GUICurrentStatus.LastCommandTime = $null
   $Script:GUICurrentStatus.CurrentWindow = $null
   $Script:GUICurrentStatus.PackagesChanged = $null
   $Script:GUICurrentStatus.IconsChanged = $null
   $Script:GUICurrentStatus.TextBoxEntryFocus = $null
   $Script:GUICurrentStatus.MouseStatus = $null
   $Script:GUICurrentStatus.CurrentMousePositionX = $null
   $Script:GUICurrentStatus.MousePositionXatTimeofPress = $null
   $Script:GUICurrentStatus.CurrentMousePositionY = $null
   $Script:GUICurrentStatus.MousePositionYatTimeofPress = $null
   $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
   $Script:GUICurrentStatus.ActionToPerform = $null
   $Script:GUICurrentStatus. SelectedAmigaPartition = $null
   $Script:GUICurrentStatus.PartitionHoveredOver = $null
   $Script:GUICurrentStatus.AvailableSpaceforImportedMBRGPTPartitionBytes = $null
   $Script:GUICurrentStatus.MBRPartitionstoImportDataTable = New-Object System.Data.DataTable
   $Script:GUICurrentStatus.RDBPartitionstoImportDataTable = New-Object System.Data.DataTable
   
   $Script:GUICurrentStatus.RunOptionstoReport.Columns.Add((New-Object System.Data.DataColumn "Setting",([string])))
   $Script:GUICurrentStatus.RunOptionstoReport.Columns.Add((New-Object System.Data.DataColumn "Value",([string])))
   $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Columns.Add((New-Object System.Data.DataColumn "Area",([string])))
   $Script:GUICurrentStatus.IssuesFoundBeforeProcessing.Columns.Add((New-Object System.Data.DataColumn "Issue",([string])))
   
   for ($i = 0; $i -lt $Script:GUICurrentStatus.MBRPartitionstoImportDataTable.Columns.Count; $i++) {
       if (($Script:GUICurrentStatus.MBRPartitionstoImportDataTable.Columns[$i].ColumnName) -eq 'SizeBytes'){
           $Script:GUICurrentStatus.MBRPartitionstoImportDataTable.Columns[$i].ColumnMapping= [System.Data.MappingType]::Hidden
       }
   }
   
   $Script:GUIActions.InstallType = 'PiStorm'
   $Script:GUIActions.ScreenModetoUse = $null
   $Script:GUIActions.ScreenModetoUseFriendlyName =$null
   $Script:GUIActions.DefaultPackagesSelected = $null 
   $Script:GUIActions.DefaultIconsetSelected = $null
   $Script:GUIActions.AvailablePackages = New-Object System.Data.DataTable
   $Script:GUIActions.AvailableIconSets = New-Object System.Data.DataTable 
   $Script:GUIActions.SelectedIconSet = $null 
   $Script:GUIActions.KickstartVersiontoUse = $null
   $Script:GUIActions.KickstartVersiontoUseFriendlyName = $null
   $Script:GUIActions.OSInstallMediaType = $null
   $Script:GUIActions.SSID = $null
   $Script:GUIActions.WifiPassword = $null
   $Script:GUIActions.FoundInstallMediatoUse = $null
   $Script:GUIActions.FoundKickstarttoUse = $null
   $Script:GUIActions.ListofRemovableMedia = $null
   $Script:GUIActions.ImportPartitionWindowStatus = $null
   $Script:GUIActions.SelectedPhysicalDiskforTransfer = $null
   $Script:GUIActions.DiskTypeSelected = $null
   $Script:GUIActions.DiskSizeSelected = $null
   $Script:GUIActions.ImageSizeSelected = $null
   $Script:GUIActions.OutputPath = $null
   $Script:GUIActions.OutputType = $null
   $Script:GUIActions.InstallMediaLocation = $null
   $Script:GUIActions.ROMLocation = $null
   $Script:GUIActions.InstallOSFiles = $true 
   $Script:GUIActions.ScreenModeType = $null
   $Script:GUIActions.ScreenModetoUseWB = $null
   $Script:GUIActions.WorkbenchBackDropEnabled = $null
   $Script:GUIActions.ScreenModeWBColourDepth = $null
   $Script:GUIActions.UnicamEnabled = $false    
   $Script:GUIActions.UnicamStartonBoot = [bool]$null
   $Script:GUIActions.UnicamScalingType = $null
   #$Script:GUIActions.UnicamPhase = $null
   $Script:GUIActions.UnicamBParameter = $null
   $Script:GUIActions.UnicamCParameter = $null
   $Script:GUIActions.UnicamSizeXPosition = $null
   $Script:GUIActions.UnicamSizeYPosition = $null
   $Script:GUIActions.UnicamOffsetXPosition = $null
   $Script:GUIActions.UnicamOffsetYPosition = $null
   $Script:GUIActions.CustomScreenMode_Width = $null
   $Script:GUIActions.CustomScreenMode_Height = $null
   $Script:GUIActions.CustomScreenMode_Framerate = $null
   $Script:GUIActions.CustomScreenMode_Aspect = $null
   $Script:GUIActions.CustomScreenMode_Margins = $null
   $Script:GUIActions.CustomScreenMode_Interlace = $null
   $Script:GUIActions.CustomScreenMode_RB = $null

   $Script:GUIActions.AvailableIconSets.Columns.Add((New-Object System.Data.DataColumn "IconSet",([String])))
   $Script:GUIActions.AvailableIconSets.Columns.Add((New-Object System.Data.DataColumn "IconSetDescription",([String])))
   $Script:GUIActions.AvailableIconSets.Columns.Add((New-Object System.Data.DataColumn "IconSetDefaultInstall",([Bool])))
   $Script:GUIActions.AvailableIconSets.Columns.Add((New-Object System.Data.DataColumn "IconSetUserSelected",([Bool])))
   for ($i = 0; $i -lt $Script:GUIActions.AvailableIconSets.Columns.Count; $i++) {
       if (($Script:GUIActions.AvailableIconSets.Columns[$i].ColumnName) -eq 'IconSet'){
           $Script:GUIActions.AvailableIconSets.Columns[$i].ReadOnly = $true
       }
       if (($Script:GUIActions.AvailableIconSets.Columns[$i].ColumnName) -eq 'IconSetDescription'){
           $Script:GUIActions.AvailableIconSets.Columns[$i].ReadOnly = $true
       }
       if (($Script:GUIActions.AvailableIconSets.Columns[$i].ColumnName) -eq 'IconSetUserSelected'){
           $Script:GUIActions.AvailableIconSets.Columns[$i].ReadOnly = $false
       }
   }
   
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "PackageNameUserSelected",([bool])))
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "PackageNameDefaultInstall",([bool])))
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "PackageNameFriendlyName",([string])))
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "PackageNameGroup",([string])))
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "PackageNameDescription",([string])))
$Script:GUIActions.AvailablePackages.Columns.Add((New-Object System.Data.DataColumn "InstallMediaFlag",([bool])))
for ($i = 0; $i -lt $Script:GUIActions.AvailablePackages.Columns.Count; $i++) {
    if (($Script:GUIActions.AvailablePackages.Columns[$i].ColumnName) -eq 'PackageNameFriendlyName'){
        $Script:GUIActions.AvailablePackages.Columns[$i].ReadOnly = $true
    }
    if (($Script:GUIActions.AvailablePackages.Columns[$i].ColumnName) -eq 'PackageNameGroup'){
        $Script:GUIActions.AvailablePackages.Columns[$i].ReadOnly = $true
    }
    if (($Script:GUIActions.AvailablePackages.Columns[$i].ColumnName) -eq 'PackageNameDescription'){
        $Script:GUIActions.AvailablePackages.Columns[$i].ReadOnly = $true
    }
    if (($Script:GUIActions.AvailablePackages.Columns[$i].ColumnName) -eq 'InstallMediaFlag'){
        $Script:GUIActions.AvailablePackages.Columns[$i].ReadOnly = $true
    }    
    if (($Script:GUIActions.AvailablePackages.Columns[$i].ColumnName) -eq 'PackageNameUserSelected'){
        $Script:GUIActions.AvailablePackages.Columns[$i].ReadOnly = $false
    }
}

     if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
        return
    }

    $Script:GUICurrentStatus.CurrentWindow = 'StartPage'
    for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
        if ($WPF_Window_Main.Children[$i].Name -eq $WPF_PackageSelection.Name){
            $WPF_Window_Main.Children.Remove($WPF_PackageSelection)
        }
        if ($WPF_Window_Main.Children[$i].Name -eq $WPF_Partition.Name){
            $WPF_Window_Main.Children.Remove($WPF_Partition)
        }
    }
    
    for ($i = 0; $i -lt $WPF_Window_Main.Children.Count; $i++) {        
        if ($WPF_Window_Main.Children[$i].Name -eq $WPF_StartPage.Name){
            $IsChild = $true
            break
        }
    }
    
    if ($IsChild -ne $true){
        $WPF_Window_Main.AddChild($WPF_StartPage)
    }

   $ReadSettings = get-content -Path $SettingsFile

    if (((($ReadSettings[0] -split ":")[0]).Trim() -ne 'Version') -or ($ReadSettings[1] -ne 'Do not edit this file! It will break Emu68 Imager! You have been warned!')) {
        Write-InformationMessage -Message "Invalid Settings File!"
        return $false #Invalid File
    }

    $VersionCheck = (($ReadSettings[0] -split ":")[-1]).Trim()

    if ($Script:Settings.Version -lt [System.version]$VersionCheck){
        Write-InformationMessage -Message "Settings File is for different version of Emu68 Imager!"
        return $false #File is for wrong version
    }

    $LoadedSettingsHeader = $null
    $GPTMBRHeader = $null
    $RDBHeader = $null
    $MBRPartitionHeader = $null
    $RDBPartitionHeader = $null
    $AvailablePackagesHeader = $null 
    $FoundInstallMediaHeader = $null
    $FoundKickstarttoUseHeader = $null

    $LoadedSettings = @()
    $GPTMBR = @()
    $RDB = @()
    $MBRPartitions = @()
    $RDBPartitions = @()
    $ImportFiles = @()
    $AvailableIconSets = New-Object System.Data.DataTable
    $AvailablePackages = New-Object System.Data.DataTable
    $FoundInstallMedia = @()
    $FoundKickstarttoUse = @()

    $ReadSettings | ForEach-Object {
        if ($_.split(';')[0] -eq 'SettingHeader'){
            $HeaderValue = $_.Replace('SettingHeader;','')
            $LoadedSettingsHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'GPTMBRHeader'){
            $HeaderValue = $_.Replace('GPTMBRHeader;','')
            $GPTMBRHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'RDBHeader'){
            $HeaderValue = $_.Replace('RDBHeader;','')
            $RDBHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'MBRPartitionHeader'){
            $HeaderValue = $_.Replace('MBRPartitionHeader;','')
            $MBRPartitionHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'RDBPartitionHeader'){
            $HeaderValue = $_.Replace('RDBPartitionHeader;','')
            $RDBPartitionHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'AvailableIconSetsUserSelectedHeader'){
            $HeaderValue = $_.Replace('AvailableIconSetsUserSelectedHeader;','')
            $AvailableIconSetsHeader = $HeaderValue.Split(';')
        }        
        elseif ($_.split(';')[0] -eq 'AvailablePackagesUserSelectedHeader'){
            $HeaderValue = $_.Replace('AvailablePackagesUserSelectedHeader;','')
            $AvailablePackagesHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'FoundInstallMediatoUseHeader'){
            $HeaderValue = $_.Replace('FoundInstallMediatoUseHeader;','')
            $FoundInstallMediaHeader = $HeaderValue.Split(';')
        }
        elseif ($_.split(';')[0] -eq 'FoundKickstarttoUseHeader'){
            $HeaderValue = $_.Replace('FoundKickstarttoUseHeader;','')
            $FoundKickstarttoUseHeader = $HeaderValue.Split(';')
        }
    }

    $ReadSettings | ForEach-Object {
        if ($_.split(';')[0] -eq 'Setting'){
            $LoadedSettings += ConvertFrom-Csv -InputObject $_ -Delimiter ';' -Header $LoadedSettingsHeader 
        }
        elseif (($_.split(';')[0] -eq 'GPTMBRDetails') -and ($GPTMBRHeader)) {
            $GPTMBR += ConvertFrom-Csv -InputObject $_ -Delimiter ';' -Header $GPTMBRHeader
        }
        elseif (($_.split(';')[0] -eq 'RDBDetails') -and ($RDBHeader)) {
            $RDB += ConvertFrom-Csv -InputObject $_ -Delimiter ';' -Header $RDBHeader
        }
        elseif (($_.split(';')[0] -eq 'MBRPartitionDetails') -and ($MBRPartitionHeader)) {
            $MBRPartitions += ConvertFrom-Csv -InputObject $_ -Delimiter ';' -Header $MBRPartitionHeader
        }
        elseif (($_.split(';')[0] -eq 'RDBPartitionDetails') -and ($RDBPartitionHeader)) {
            $RDBPartitions += ConvertFrom-Csv -InputObject $_ -Delimiter ';' -Header $RDBPartitionHeader
        }
        elseif (($_.split(';')[0] -eq 'AvailableIconSetsUserSelectedDetails') -and ($AvailableIconSetsHeader)) {
            $AvailableIconSets += ConvertFrom-Csv -InputObject $_.Replace('AvailableIconSetsUserSelectedDetails;','')   -Delimiter ';' -Header $AvailableIconSetsHeader 
        }
        elseif (($_.split(';')[0] -eq 'AvailablePackagesUserSelectedDetails')  -and ($AvailablePackagesHeader)) {
            $AvailablePackages += ConvertFrom-Csv -InputObject $_.Replace('AvailablePackagesUserSelectedDetails;','')   -Delimiter ';' -Header $AvailablePackagesHeader 
        }
        elseif (($_.split(';')[0] -eq 'FoundInstallMediatoUseDetails')  -and ($FoundInstallMediaHeader)) {
            $FoundInstallMedia += ConvertFrom-Csv -InputObject $_.Replace('FoundInstallMediatoUseDetails;','')  -Delimiter ';' -Header $FoundInstallMediaHeader
        }
        elseif (($_.split(';')[0] -eq 'FoundKickstarttoUseDetails') -and ($FoundKickstarttoUseHeader)) {
            $FoundKickstarttoUse += ConvertFrom-Csv -InputObject $_.replace('FoundKickstarttoUseDetails;','')  -Delimiter ';' -Header $FoundKickstarttoUseHeader
        }
    }

   # $ImportFilesHeader = ('Type','Partition','FullPath','Size','CreationTime','Source','PathHeader')
   
   # Remove existing Partitions 
   
   $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = $null
   
   $WPF_DP_MediaSelect_Dropdown.SelectedItem = $null
   
    Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
    
    if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
        Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
    }

    $GPTMBR | ForEach-Object {
        $_.DiskSizeBytes = [decimal]$_.DiskSizeBytes
        $_.MBROverheadBytes = [decimal]$_.MBROverheadBytes
    }

    $MBRPartitions | ForEach-Object {
        $_.StartingPositionBytes  = [int64]$_.StartingPositionBytes  
        $_.PartitionSizeBytes = [int64]$_.PartitionSizeBytes
        $_.ImportedFilesSpaceBytes = [int64]$_.ImportedFilesSpaceBytes
    }

    $RDBPartitions | ForEach-Object {
        $_.StartingPositionBytes  = [int64]$_.StartingPositionBytes  
        $_.PartitionSizeBytes = [int64]$_.PartitionSizeBytes
        $_.ImportedFilesSpaceBytes = [int64]$_.ImportedFilesSpaceBytes
    }

    $LoadedSettings | ForEach-Object {
        if ($_.Setting -eq 'DiskTypeSelected'){
            $DiskTypetouse = $_.Value       
        }        
        else {
            (Get-Variable -Scope Script -Name "GUIActions").Value.$($_.Setting) = $_.Value
        }
    }  
   
    if ($FoundKickstarttoUse.KickstartPath){
        if (Test-Path $FoundKickstarttoUse.KickstartPath){
            if ((get-filehash -path $FoundKickstarttoUse.KickstartPath -Algorithm MD5).hash -eq (Get-InputCSVs -ROMHashes | Where-Object {$_.Kickstart_version -eq $Script:GUIActions.KickstartVersiontoUse}).hash){
                $Script:GUIActions.FoundKickstarttoUse = $FoundKickstarttoUse | Select-Object 'Kickstart_Version','FriendlyName','Sequence','IncludeorExclude','ExcludeMessage','Fat32Name','KickstartPath'            
            }
        }
    }

 
    foreach ($line in $AvailablePackages ){
        $Array = @()
        $array += $line.PackageNameUserSelected
        $array += $line.PackageNameDefaultInstall
        $array += $line.PackageNameFriendlyName
        $array += $line.PackageNameGroup
        $array += $line.PackageNameDescription
        $array += $line.InstallMediaFlag
        [void]$Script:GUIActions.AvailablePackages.Rows.Add($array)
    }
    
    $IndexForSelectedIconSet = $null
    $Counter = 0

    foreach ($line in  $AvailableIconSets){
       $Array = @()
       $array += $line.IconSet
       $array += $line.IconSetDescription
       $array += $line.IconSetDefaultInstall
       $array += $line.IconSetUserSelected
       [void]$Script:GUIActions.AvailableIconSets.Rows.Add($array)
       if ($Script:GUIActions.SelectedIconSet -eq $line.IconSet){
        $IndexForSelectedIconSet = $Counter
       }
       $Counter ++
    }
   
        $WPF_PackageSelection_Datagrid_Packages.ItemsSource = $Script:GUIActions.AvailablePackages.DefaultView  
        $WPF_PackageSelection_Datagrid_IconSets.ItemsSource = $Script:GUIActions.AvailableIconSets.DefaultView

        if ($IndexForSelectedIconSet -ne $null){
            $WPF_PackageSelection_Datagrid_IconSets.SelectedIndex  =  $IndexForSelectedIconSet
            $WPF_PackageSelection_CurrentlySelectedIconSet_Value.text = $WPF_PackageSelection_Datagrid_IconSets.SelectedItem.IconSet

        }

        
    $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $false

    $WPF_StartPage_ScreenMode_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseFriendlyName
    $WPF_StartPage_KickstartVersion_Dropdown.SelectedItem = $Script:GUIActions.KickstartVersiontoUseFriendlyName
    $WPF_StartPage_Password_Textbox.Text = $Script:GUIActions.Password
    $WPF_StartPage_SSID_Textbox.Text = $Script:GUIActions.SSID
    
    $MissingFiles = $false

    $HashTableforInstallMedia = @{} # Clear Hash
    Get-InputCSVs -InstallMediaHashes | ForEach-Object {
        $HashTableforInstallMedia[$_.Hash] = $null
    }

    $FoundInstallMedia | ForEach-Object {
        If (Test-Path $_.Path){
            $HashtoCheck = (Get-FileHash -path $_.path -Algorithm MD5).hash
            if (-not ($HashTableforInstallMedia.ContainsKey($HashtoCheck))){
                $MissingFiles = $true  
                break              
            }
        }
        else {
            $MissingFiles = $true
        } 
    }

    if ($MissingFiles -eq $false){        
        $Script:GUICurrentStatus.IconsChanged = $false
        $Script:GUICurrentStatus.PackagesChanged =$false
        $Script:GUIActions.FoundInstallMediatoUse = $FoundInstallMedia 
    }

    if ($DiskTypetouse){
        $ImportDisk = $true
        if ($Script:GUIActions.OutputType -eq "Disk"){
            $Script:GUIActions.ListofRemovableMedia = Get-RemovableMedia
            $WPF_DP_MediaSelect_Dropdown.Items.Clear()
            foreach ($Disk in $Script:GUIActions.ListofRemovableMedia){
                $WPF_DP_MediaSelect_DropDown.AddChild($Disk.FriendlyName)     

            }
                
            if ($Script:GUIActions.OutputPath){
                $Counter = 0
                $Script:GUIActions.ListofRemovableMedia | ForEach-Object {
                    if ($_.HSTDiskName -eq $Script:GUIActions.OutputPath){
                        if (($_.SizeofDisk*1024) -lt $GPTMBR.DiskSizeBytes){
                            $null = Show-WarningorError -Msg_Header "Disk Not Available!" -Msg_Body "The SD card you used is not available. Cannot import disk!" -BoxTypeError -ButtonType_OK
                            $ImportDisk = $false
                        } 
                        else {
                             $CountertoUse = $Counter
                            
                        }
                    }
                    $Counter ++
                }
            }

        }

         if ($GPTMBR.GPTMBRDisk -eq "NOTAVAILABLE"){
            $ImportDisk = $false
         }

        if ($ImportDisk -eq $true){
            
                Set-InitialDiskValues -DiskType $DiskTypetouse -SizeBytes $GPTMBR.DiskSizeBytes -LoadSettings
                $WPF_DP_Disk_GPTMBR.NumberofPartitionsMBR = $GPTMBR.NumberofPartitionsMBR
                $WPF_DP_Disk_GPTMBR.NextPartitionMBRNumber = $GPTMBR.NextPartitionMBRNumber
    
                $MBRPartitions | ForEach-Object {
                    if ($_.PartitionType -eq 'MBR' -and $_.PartitionSubType -eq 'FAT32'){
                        if ($_.DefaultGPTMBRPartition -eq 'True'){
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -DefaultPartition $true -SizeBytes ($($_.PartitionSizeBytes)) -VolumeName $_.VolumeName -StartingPositionBytes ($($_.StartingPositionBytes))                             
                        }
                        elseif ($_.ImportedPartition -eq 'True') { 
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -PathtoImportedPartition $_.ImportedPartitionPath -ImportedPartition $true -ImportedPartitionMethod $_.ImportedPartitionMethod -SizeBytes ($($_.PartitionSizeBytes)) -StartingPositionBytes ($($_.StartingPositionBytes)) -VolumeName $_.VolumeName
                        }
                        else {
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -SizeBytes ($($_.PartitionSizeBytes)) -StartingPositionBytes ($($_.StartingPositionBytes)) -VolumeName $_.VolumeName
                        } 
                    }
                    elseif ($_.PartitionType -eq 'MBR' -and $_.PartitionSubType -eq 'ID76'){
                        if ($_.DefaultGPTMBRPartition -eq 'True'){
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -DefaultPartition $true -SizeBytes ($($_.PartitionSizeBytes)) -StartingPositionBytes ($($_.StartingPositionBytes)) 
                            Add-AmigaDisktoID76Partition -ID76PartitionName $_.Name
                        }
                        elseif ($_.ImportedPartition -eq 'True') {
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -PathtoImportedPartition $_.ImportedPartitionPath -ImportedPartition $true -ImportedPartitionMethod $_.ImportedPartitionMethod -SizeBytes ($($_.PartitionSizeBytes)) -StartingPositionBytes ($($_.StartingPositionBytes))
                            Add-AmigaDisktoID76Partition -ID76PartitionName $_.Name -ImportedDisk
                        }
                        else {
                            Add-GUIPartitiontoGPTMBRDisk -LoadSettings -PartitionType $_.PartitionType -PartitionSubType $_.PartitionSubType -NewPartitionNameFromSettings $_.Name -AddType 'SpecificPosition' -SizeBytes ($($_.PartitionSizeBytes)) -StartingPositionBytes ($($_.StartingPositionBytes))
                            Add-AmigaDisktoID76Partition -ID76PartitionName $_.Name 
                        }
            
                        foreach ($AmigaDisk in $RDB) {
                            if ($AmigaDisk.Name -eq "$($_.Name)_AmigaDisk"){
                                (Get-Variable -name "$($_.Name)_AmigaDisk").Value.NextPartitionNumber = [int]$AmigaDisk.NextPartitionNumber
                                (Get-Variable -name "$($_.Name)_AmigaDisk").Value.ID76PartitionParent = $AmigaDisk.ID76PartitionParent
                                break
                            }
                        } 
                    }
                    
                } 

                $RDBPartitions | ForEach-Object {
                    $AmigaDiskName = ($_.Name.Substring(0,($_.Name.IndexOf('_AmigaDisk_')+10)))
                    if ($_.DefaultAmigaWorkbenchPartition -eq 'True'){
                        Add-GUIPartitiontoAmigaDisk -LoadSettings -NewPartitionNameFromSettings $_.Name -AmigaDiskName $AmigaDiskName -SizeBytes ($($_.PartitionSizeBytes)) -AddType 'AtEnd' -PartitionTypeAmiga 'Workbench' -VolumeName $_.VolumeName -DeviceName $_.DeviceName -Buffers $_.Buffers -DosType $_.DosType -MaxTransfer $_.MaxTransfer -Bootable $_.Bootable -NoMount $_.NoMount -Priority $_.Priority -Mask $_.Mask           
            
                    }
                    elseif ($_.DefaultAmigaWorkPartition -eq 'True'){
                        Add-GUIPartitiontoAmigaDisk -LoadSettings -NewPartitionNameFromSettings $_.Name -AmigaDiskName $AmigaDiskName -SizeBytes ($($_.PartitionSizeBytes)) -AddType 'AtEnd' -PartitionTypeAmiga 'Work' -VolumeName $_.VolumeName -DeviceName $_.DeviceName -Buffers $_.Buffers -DosType $_.DosType -MaxTransfer $_.MaxTransfer -Bootable $_.Bootable -NoMount $_.NoMount -Priority $_.Priority -Mask $_.Mask -ImportedFilesPath $_.ImportedFilesPath -ImportedFilesSpaceBytes $_.ImportedFilesSpaceBytes  
                    }
                    elseif ($_.ImportedPartition -eq 'True'){
                        Add-GUIPartitiontoAmigaDisk -LoadSettings -NewPartitionNameFromSettings $_.Name -AmigaDiskName $AmigaDiskName -SizeBytes ($($_.PartitionSizeBytes)) -AddType 'AtEnd' -ImportedPartition $true -ImportedPartitionMethod $_.ImportedPartitionMethod -VolumeName $_.VolumeName -DeviceName $_.DeviceName -Buffers $_.Buffers -DosType $_.DosType -MaxTransfer $_.MaxTransfer -Bootable $_.Bootable -NoMount $_.NoMount -Priority $_.Priority -Mask $_.Mask   
                    }
                    else {
                        Add-GUIPartitiontoAmigaDisk -LoadSettings -NewPartitionNameFromSettings $_.Name -AmigaDiskName $AmigaDiskName -SizeBytes ($($_.PartitionSizeBytes)) -AddType 'AtEnd' -VolumeName $_.VolumeName -DeviceName $_.DeviceName -Buffers $_.Buffers -DosType $_.DosType -MaxTransfer $_.MaxTransfer -Bootable $_.Bootable -NoMount $_.NoMount -Priority $_.Priority -Mask $_.Mask -ImportedFilesPath $_.ImportedFilesPath -ImportedFilesSpaceBytes $_.ImportedFilesSpaceBytes  
                    } 
            
                }   

                     
            if ($Script:GUIActions.OutputType -eq "Disk"){
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Disk"
                $WPF_DP_MediaSelect_DropDown.SelectedIndex = $CountertoUse
            }
            elseif ($Script:GUIActions.OutputType -eq "Image"){
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Image"
                $Script:GUIActions.ImageSizeSelected = $true
            }

        }
        else {
                if ($Script:GUIActions.OutputType -eq "Disk"){
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Disk"
                $WPF_DP_MediaSelect_DropDown.SelectedIndex = $CountertoUse
            }
            elseif ($Script:GUIActions.OutputType -eq "Image"){
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Image"
            }
        }
    }
    
    $Script:GUICurrentStatus.ForceRecheckAmigaPartitionsandBoundaries = $true
    
    if ($ImportDisk -eq $true){
        Update-UI -MainWindowButtons -Emu68Settings -DiskPartitionWindow -UpdateInputBoxes -Buttons -PhysicalvsImage -CheckforRunningImage -freespacealert -WBScreenModeUpdate

    }
    elseif ($Script:GUIActions.OutputPath) {
        Update-UI -MainWindowButtons -Emu68Settings -DiskPartitionWindow -UpdateInputBoxes -Buttons -PhysicalvsImage -CheckforRunningImage -WBScreenModeUpdate  
    }
    else{
    Update-UI -MainWindowButtons -Emu68Settings UpdateInputBoxes -Buttons -PhysicalvsImage -CheckforRunningImage -WBScreenModeUpdate
    }
    
    if (-not $Script:GUIActions.ListofRemovableMedia){
        $Script:GUIActions.ListofRemovableMedia = Get-RemovableMedia
    }


    $Script:GUICurrentStatus.LoadingSettings = $null

    return $true

}





