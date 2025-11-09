   
function Write-DiskIconsandPositions {
    param (

    )
    
    $HashTableforDefaultDisks = @{} # Clear Hash
    $HSTAmigaScript = [System.Collections.Generic.List[PSCustomObject]]::New()
    $DiskIconsPath = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\IconFiles\DiskIconstoUse")
    $SourceIconsPath = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\IconFiles")
    
    
    $DiskDefaults = Get-InputCSVs -Diskdefaults 
    
    $DiskDefaults | ForEach-Object {
        $DeviceNameVolumeName = "$($_.DeviceName)$($_.VolumeName)"
        $HashTableforDefaultDisks[$DeviceNameVolumeName] = @($_.Disk,$_.IconX,$_.IconY) 
        if ($_.Disk -eq "EMU68BOOT"){
            $SourcePath = "$SourceIconsPath\Emu68BootDrive\disk.info" 
            $DestinationPath = "$DiskIconsPath\$($_.DeviceName)\disk.info"
            if (-not (test-path (Split-Path -Path $DestinationPath -Parent))){
                $null = new-item (Split-Path -Path $DestinationPath -Parent) -ItemType Directory
            }
            $null = Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
           # $HSTAmigaScript += "icon update $DestinationPath --type 1 --current-x $($_.IconX) --current-y $($_.IconY)"
        }
    }
        
    
    $IconX = 0
    $IconY = 0
    
    
    if (-not (test-path $DiskIconsPath)){
        $null = new-item -Path $DiskIconsPath -ItemType Directory
    } 
    
    $ListofDisks = $Script:GUICurrentStatus.PathstoRDBPartitions
    $ListofDisks | Add-Member -NotePropertyName 'DeviceNameVolumeName' -NotePropertyValue $null -Force
    $ListofDisks | Add-Member -NotePropertyName 'IconX' -NotePropertyValue $null -Force
    $ListofDisks | Add-Member -NotePropertyName 'IconY' -NotePropertyValue $null -Force
    $ListofDisks |ForEach-Object {
        $_.DeviceNameVolumeName = "$($_.DeviceName)$($_.VolumeName)"
    }
    
    $IconYtoUseWork = [int]$Script:Settings.AmigaWorkDiskIconYPosition
    
    $ListofDisks | ForEach-Object {
        if ($HashTableforDefaultDisks.ContainsKey($_.DeviceNameVolumeName)){
            $_.IconX = [int]($HashTableforDefaultDisks.($_.DeviceNameVolumeName)[1])
            $_.IconY = [int]($HashTableforDefaultDisks.($_.DeviceNameVolumeName)[2])     
            if (($HashTableforDefaultDisks.($_.DeviceNameVolumeName)[0]) -eq "System"){
                $SourcePath = "$SourceIconsPath\SystemDrive\disk.info" 
            }
            elseif (($HashTableforDefaultDisks.($_.DeviceNameVolumeName)[0]) -eq "Work"){
                $SourcePath = "$SourceIconsPath\WorkDrive\disk.info" 
            }    
        }
        else {
            $SourcePath = "$SourceIconsPath\WorkDrive\disk.info"         
            $_.IconX = [int]$Script:Settings.AmigaWorkDiskIconXPosition
            $_.IconY =  $IconYtoUseWork
            $IconYtoUseWork += [int]$Script:Settings.AmigaWorkDiskIconYPositionSpacing
        }
        $DestinationPath = "$DiskIconsPath\$($_.DeviceName)\disk.info"
        if (-not (test-path (Split-Path -Path $DestinationPath -Parent))){
            $null = new-item (Split-Path -Path $DestinationPath -Parent) -ItemType Directory
        }   
        #Write-debug "Source is: $SourcePath Destination is: $DestinationPath"  
        $null = Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    
      #  $HSTAmigaScript += "icon update $DestinationPath --type 1 --current-x $($_.IconX) --current-y $($_.IconY)"   
    }

   # Start-HSTAmigaCommands -HSTScript $HSTAmigaScript
}

            
