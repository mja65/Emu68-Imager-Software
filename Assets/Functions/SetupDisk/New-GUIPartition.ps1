function New-GUIPartition {
    param (
        $PartitionName,
        $PartitionType,
        $PartitionSubType,
        [switch]$DefaultPartition,
        $PartitionTypeAmiga,
        [switch]$ImportedPartition,
        $ImportedPartitionMethod
    )
    
    # Write-debug "PartitionType is: $PartitionType PartitionSubType is:  $PartitionSubType DefaultPartition is: $DefaultPartition"
    # $WPF_MainWindow.Close()
    # exit

    if ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'FAT32'){
        $NewPartition_XML = get-content '.\Assets\WPF\SetupDisk\PartitionMBR.xaml'
    }
    elseif ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'ID76'){
        $NewPartition_XML = get-content '.\Assets\WPF\SetupDisk\PartitionID76.xaml'
    }
    elseif ($PartitionType -eq 'Amiga'){
        $NewPartition_XML = get-content '.\Assets\WPF\SetupDisk\PartitionAmiga.xaml'
    }
    elseif ($PartitionType -eq 'GPT'){
        Write-ErrorMessage -Message "Coding Error - New-GUIPartition!"
        $WPF_MainWindow.Close()
        exit
    }
    else {
        Write-ErrorMessage -Message "Coding Error - New-GUIPartition! Different MBR partitions?"
        $WPF_MainWindow.Close()
        exit
    }

    If ($DefaultPartition){
        if (($PartitionType -eq 'MBR') -and ($PartitionSubType -eq 'FAT32' -or $PartitionSubType -eq 'ID76')){
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

    [xml]$NewPartition_XAML = $NewPartition_XML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
    
    $reader = (New-Object System.Xml.XmlNodeReader $NewPartition_XAML)

    $NewPartition = [Windows.Markup.XamlReader]::Load( $reader)

    $NewPartition | Add-Member -NotePropertyMembers @{
        PartitionName = $PartitionName
        VolumeName = $null
        CanRenameVolume = $null
        ImportedPartition = $false
        ImportedPartitionMethod = $null
        ImportedPartitionPath = $null
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

    # $Fields =  ('FullPath','Size','LastWriteTime','CreationTime','Type')
         
    # [void]$NewPartition.ImportedFiles.Columns.AddRange($Fields)

    # $NewPartition.ImportedFiles.Add("FullPath", [string])
    # $NewPartition.ImportedFiles.Add("Size", [decimal])
    # $NewPartition.ImportedFiles.Add("LastWriteTime", [datetime])
    # $NewPartition.ImportedFiles.Add("CreationTime", [datetime])
    # $NewPartition.ImportedFiles.Add("Type", [string])

    If (($PartitionType -eq 'MBR') -and ($PartitionSubType -eq 'FAT32' -or $PartitionSubType -eq 'ID76')){  
        $NewPartition | Add-Member -NotePropertyMembers @{
            ImportedGPTMBRPartitionNumber = $null
        }       
        $NewPartition.PartitionTypeGPTMBRorAmiga = 'GPTMBR'
        if ($PartitionSubType -eq 'ID76'){
            $NewPartition | Add-Member -NotePropertyName AmigaDiskName -NotePropertyValue $null  
        }
        if ($DefaultGPTMBRPartition -eq $true){
            $NewPartition.CanRenameVolume = $false
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanResizeRight = $true
            if ($PartitionSubType -eq 'FAT32'){
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
        elseif ($ImportedPartition){
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanRenameVolume = $false
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeLeft = $false
            $NewPartition.CanResizeRight = $false
            $NewPartition.CanMove = $true

        }
        else{
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeRight = $true
            $NewPartition.CanResizeLeft =$true
            $NewPartition.CanMove = $true
            if ($PartitionSubType -eq 'FAT32'){
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
            ImportedPartitionOffsetBytes = $null
            ImportedPartitionEndBytes = $null
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
        elseif (($ImportedPartition)-and $ImportedPartitionMethod -eq 'Direct'){
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanDelete = $true
            $NewPartition.CanResizeLeft = $false
            $NewPartition.CanResizeRight = $false
            $NewPartition.CanMove = $true
            $NewPartition.CanChangeMask = $true
            $NewPartition.CanChangeBootable = $true
            $NewPartition.CanChangeDosType = $false
            $NewPartition.CanChangeBuffers =$true
            $NewPartition.CanChangePriority = $true
            $NewPartition.CanChangeMountable = $true
            $NewPartition.CanRenameDevice = $true
            $NewPartition.CanRenameVolume = $true
            $NewPartition.CanChangeMaxTransfer = $true    
        }
        elseif (($ImportedPartition)  -and $ImportedPartitionMethod -eq 'Derived'){
            $NewPartition.CanImportFiles = $false
            $NewPartition.CanDelete = $false
            $NewPartition.CanResizeLeft = $false
            $NewPartition.CanResizeRight = $false
            $NewPartition.CanMove = $false
            $NewPartition.CanChangeMask = $true
            $NewPartition.CanChangeBootable = $true
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
     
    #$NewPartition.PartitionSizeBytes = $SizeBytes

    $TotalChildren = $NewPartition.Children.Count-1
    
    for ($i = 0; $i -le $TotalChildren; $i++) {
        if ($NewPartition.Children[$i].Name -eq 'FullSpace_Rectangle'){
            if ($DefaultPartition){
                if ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'FAT32'){
                    $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.DefaultMBRBrush
                }
                elseif ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'ID76'){
                    $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.DefaultID76Brush
                }
                elseif ($DefaultAmigaWorkbenchPartition -eq $true){
                    $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.DefaultAmigaWorkbenchPartitionBrush
                }
                # elseif ($DefaultAmigaWorkPartition -eq $true){
                #     $NewPartition.Children[$i].Fill=$WPF_MainWindow.Resources.DefaultAmigaWorkPartitionBrush
                # }
            }
            else {
                if ($ImportedPartition){
                    if ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'FAT32'){
                        $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.ImportedMBRBrush
                    }
                    elseif ($PartitionType -eq 'MBR' -and $PartitionSubType -eq 'ID76'){
                        $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.ImportedID76Brush
                    }
                    elseif ($PartitionType -eq 'Amiga'){
                        $NewPartition.Children[$i].Fill = $WPF_MainWindow.Resources.ImportedAmigaPartitionBrush
                    }

                }

            }
        }
    }

    return $NewPartition
}
