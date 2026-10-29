function New-GUIPartition {
    param (
        $PartitionName,
        $PartitionType,
        $PartitionSubType,
        [switch]$DefaultPartition,
        $PartitionTypeAmiga
    )
    
    # Write-debug "PartitionName is: $PartitionName PartitionType is: $PartitionType PartitionSubType is: $PartitionSubType DefaultPartition is: $DefaultPartition PartitionTypeAmiga is: $PartitionTypeAmiga"
    # $WPF_MainWindow.Close()
    # exit

    # $PartitionType = "GPT"
    # $PartitionSubType = "System"

    $VisualtoUse = If ($PartitionType -eq "MBR" -or $PartitionType -eq "GPT") {
        $Script:GUIPartitionVisuals.where({ $_.PartitionType -eq  $PartitionType -and $_.PartitionSubType -eq $PartitionSubType}) 
    }
    elseif ($PartitionType -eq "Amiga"){
        $Script:GUIPartitionVisuals.where({ $_.PartitionType -eq  $PartitionType -and $_.PartitionSubType -eq $PartitionTypeAmiga }) 
    }
        
    $NewPartition_XML = get-content '.\Assets\WPF\SetupDisk\Partition.xaml'
    [xml]$NewPartition_XAML = $NewPartition_XML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
    $reader = (New-Object System.Xml.XmlNodeReader $NewPartition_XAML)
    $NewPartition = [Windows.Markup.XamlReader]::Load( $reader)
    if ($DefaultPartition){
        $NewPartition.FindName("FullSpace_Rectangle").Fill = Get-VisualBrushDefaultPartition -Colour $VisualtoUse.DefaultColour      
    }
    else  {
        #Write-host "Colour for New partition: $([System.Windows.Media.BrushConverter]::new().ConvertFromString($VisualtoUse.Colour))"
        $NewPartition.FindName("FullSpace_Rectangle").Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($VisualtoUse.Colour)
    }


    If ($DefaultPartition){
        if ($PartitionType -eq 'MBR' -or $PartitionType -eq 'GPT'){
            $DefaultGPTMBRPartition = $true
        }
        elseif ($PartitionType -eq 'Amiga'){
            if ($PartitionTypeAmiga -eq 'Workbench'){
                $DefaultAmigaWorkbenchPartition = $true
            }
            elseif ($PartitionTypeAmiga -eq 'Work'){
                $DefaultAmigaWorkPartition = $true
            }
        }
    }
    else {
        $DefaultGPTMBRPartition = $false
        $DefaultAmigaWorkPartition = $false
        $DefaultAmigaWorkPartition = $false
    }

    $NewPartition | Add-Member -NotePropertyMembers @{
        PartitionName = $PartitionName
        VolumeName = $null
        CanRenameVolume = $null
        PartitionType = $PartitionType
        PartitionSubType = $PartitionSubType 
        StartingPositionBytes = $null
        StartingPositionSector = $null
        PartitionSizeBytes = $null  
        PartitionTypeGPTMBRorAmiga = $null
        DefaultGPTMBRPartition = $DefaultGPTMBRPartition
        DefaultAmigaWorkbenchPartition = $DefaultAmigaWorkbenchPartition
        DefaultAmigaWorkPartition = $DefaultAmigaWorkPartition
        CanResizeLeft = $null
        CanResizeRight = $null
        CanMove = $null
        CanDelete = $null
        CanImportFiles = $null
        ImportedFilesSpaceBytes = 0
        #ImportedFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
        ImportedFilesPath  = $null
    }

    If (($PartitionType -eq 'MBR') -or ($PartitionType -eq 'GPT')){    
        $NewPartition.PartitionTypeGPTMBRorAmiga = 'GPTMBR'
        if (($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'ID76') -or ($PartitionType -eq 'GPT' -and $PartitionSubType -eq "Amiga")){
            $NewPartition | Add-Member -NotePropertyName AmigaDiskName -NotePropertyValue $null -Force
        }
        if ($DefaultGPTMBRPartition -eq $true){
            $NewPartition.CanRenameVolume = $false
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanResizeRight = $true
            if (($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'FAT32') -or ($PartitionType -eq 'GPT' -and $PartitionSubType -eq 'Data') -or ($PartitionType -eq 'GPT' -and $PartitionSubType -eq 'System') ){
                $NewPartition.CanDelete = $false
                $NewPartition.CanMove = $false
                $NewPartition.CanResizeLeft =$false
            }
            else{
                $NewPartition.CanDelete = $true
                $NewPartition.CanMove = $true
                $NewPartition.CanResizeLeft =$true
            }
        }
        else{
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeRight = $true
            $NewPartition.CanResizeLeft =$true
            $NewPartition.CanMove = $true
            if (($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'FAT32') -or ($PartitionType -eq 'GPT' -and $PartitionSubType -eq 'Data')){
                $NewPartition.CanRenameVolume = $true
            }
            else {
                $NewPartition.CanRenameVolume = $false
            }
        }
    }
    elseif ($PartitionType -eq 'Amiga'){
        $NewPartition.PartitionTypeGPTMBRorAmiga='Amiga'
        $NewPartition | Add-Member -NotePropertyMembers @{
            PartitionSizeonDiskBytes = $null
            DeviceName = $null
            Buffers = $null
            DosType = $null
            MaxTransfer = $null
            Mask = $null
            Bootable = $null
            NoMount = $null
            Priority = $null
            VolumeNameOriginalImportedValue = $null
            DeviceNameOriginalImportedValue = $null
            BuffersOriginalImportedValue = $null
            DosTypeOriginalImportedValue = $null
            MaskOriginalImportedValue = $null
            MaxTransferOriginalImportedValue = $null
            BootableOriginalImportedValue = $null
            NoMountOriginalImportedValue = $null
            PriorityOriginalImportedValue = $null
            CanChangeBuffers = $null
            CanRenameDevice = $null
            CanChangeMaxTransfer = $null
            CanChangeBootable = $null
            CanChangeDosType = $null
            CanChangeMountable = $null
            CanChangePriority = $null
            CanChangeMask = $null

        }

        if ($DefaultAmigaWorkbenchPartition -eq $true){
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeLeft = $true
            $NewPartition.CanResizeRight = $true
            $NewPartition.CanMove = $true
            $NewPartition.CanChangeBootable = $false
            $NewPartition.CanChangeMask = $false
            $NewPartition.CanChangeDosType = $false
            $NewPartition.CanChangeBuffers = $true
            $NewPartition.CanChangePriority = $true
            $NewPartition.CanChangeMountable = $false
            $NewPartition.CanRenameDevice = $false
            $NewPartition.CanRenameVolume = $false
            $NewPartition.CanChangeMaxTransfer = $true
        }
        elseif ($DefaultAmigaWorkPartition -eq $true){
            $NewPartition.CanImportFiles = $true
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeRight = $true
            $NewPartition.CanMove = $true
            $NewPartition.CanResizeLeft =$true
            $NewPartition.CanChangeBootable = $true
            $NewPartition.CanChangeMask = $false
            $NewPartition.CanChangeDosType = $false
            $NewPartition.CanChangeBuffers =$true
            $NewPartition.CanChangePriority = $true
            $NewPartition.CanChangeMountable = $true
            $NewPartition.CanRenameDevice = $true
            $NewPartition.CanRenameVolume = $true
            $NewPartition.CanChangeMaxTransfer = $true
        }
        else{
            $NewPartition.CanImportFiles = $true
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeLeft =$true
            $NewPartition.CanResizeRight = $true
            $NewPartition.CanMove = $true
            $NewPartition.CanChangeBootable = $true
            $NewPartition.CanChangeMask = $false
            $NewPartition.CanChangeDosType = $false
            $NewPartition.CanChangeBuffers =$true
            $NewPartition.CanChangePriority = $true
            $NewPartition.CanChangeMountable = $true
            $NewPartition.CanRenameDevice = $true
            $NewPartition.CanRenameVolume = $true
            $NewPartition.CanChangeMaxTransfer = $true    
        }
    }
      
    return $NewPartition
}
