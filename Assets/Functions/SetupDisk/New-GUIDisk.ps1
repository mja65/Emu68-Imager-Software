function New-GUIDisk {
    param (
    $DiskType
    )

    $NewDisk_Grid = New-Object System.Windows.Controls.Grid

    $NewDisk = New-Object System.Windows.Shapes.Rectangle
    $NewDisk.HorizontalAlignment = "Left" 
    $NewDisk.VerticalAlignment = "Top"
    $NewDisk.Height = $Script:Settings.DiskHeightPixels 
    $NewDisk.Stroke = "Black"
    $NewDisk.Fill = "White"
    $NewDisk.Width = $Script:Settings.DiskWidthPixels
    $NewDisk.Name = "DiskBackground"
    
    if ($DiskType -eq 'MBR'){

        $NewDisk_Grid | Add-Member -NotePropertyMembers @{
            CanAddPartition = $null
            DiskType = 'MBR'
            GPTMBROverheadBytes = $Script:Settings.GPTMBROverheadBytes
            GPTOverheadBytes = 0
            NumberofPartitionsGPTMBR = 0
            NumberofPartitionsGPT = 0
            NextPartitionGPTMBRNumber = 1
            NextPartitionGPTNumber = 1
        }
    }

    elseif ($DiskType -eq 'Amiga'){
        $NewDisk_Grid | Add-Member -NotePropertyMembers @{
            CanAddPartition = $null
            RDBOverheadBytes = Get-AmigaRDBOverheadBytes
            DiskType = 'Amiga'
            ID76PartitionParent = $null
            NextPartitionNumber = 1
        }

    }
    elseif ($DiskType -eq 'GPT'){
        $NewDisk_Grid | Add-Member -NotePropertyMembers @{
            CanAddPartition = $null
            DiskType = 'GPT'
            GPTMBROverheadBytes = $Script:Settings.GPTMBROverheadBytes
            GPTOverheadBytes = 0
            NumberofPartitionsGPTMBR = 0
            NumberofPartitionsGPT = 0
            NextPartitionGPTMBRNumber = 1
            NextPartitionGPTNumber = 1
        }
    }
    
    $NewDisk_Grid | Add-Member -NotePropertyMembers @{
        DiskSizeBytes = 0
        DiskSizeAmigatoGPTMBROverhead = 0
        DiskSizePixels = 0
        BytestoPixelFactor = 0
        LeftDiskBoundary = $null
        RightDiskBoundary = $null
    }
    
    $NewDisk_Grid.AddChild($NewDisk)
    
    return $NewDisk_Grid

}
