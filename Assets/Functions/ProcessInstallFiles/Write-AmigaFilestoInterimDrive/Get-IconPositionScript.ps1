function Get-IconPositionScript {
    param (

    [Switch]$Emu68Boot,
    [Switch]$AmigaDrives

    )

    $IconPosScript = @()
    
    $IconPosScript += "echo `"Positioning icons...`""
    $DefaultDisks = Get-InputCSVs -Diskdefaults
    
    if ($AmigaDrives){
        Get-InputCSVs -IconPositions | ForEach-Object {
            if ($_.DrawerX){
               $DrawerXtoUse = "DXPOS $($_.DrawerX) "
           }
           if ($_.DrawerY){
               $DrawerYtoUse = "DYPOS $($_.DrawerY) "
           }
           if ($_.DrawerWidth){
               $DrawerWidthToUse = "DWIDTH $($_.DrawerWidth) "
           }
           if ($_.DrawerHeight){
               $DrawerHeightToUse = "DHEIGHT $($_.DrawerHeight)"
           }
           $Remainder = "$DrawerXtoUse$DrawerYtoUse$DrawerWidthToUse$DrawerHeightToUse"
           $IconPosScript += "iconpos >NIL: `"SYS:$($_.File)`" type=$($_.Type) $($_.IconX) $($_.IconY) $Remainder"
        }
       
        if  ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries){
            $ListofDisks = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries
        }
        else {
            $ListofDisks = (Get-AllGUIPartitionBoundaries -Amiga)
        }

        $HashTableforDefaultDisks = @{} # Clear Hash
        Get-InputCSVs -Diskdefaults | ForEach-Object {
            $HashTableforDefaultDisks[$_.DeviceName] = @($_.IconX,$_.IconY) 
        }
        
        $IconX = 0
        $IconY = 0
         
        foreach ($Disk in $ListofDisks) {
            if ($HashTableforDefaultDisks.ContainsKey($Disk.Partition.DeviceName)){
                $IconX = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[0])
                $IconY = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[1])
            }
            else {
                $IconX = [int]$Script:Settings.AmigaWorkDiskIconXPosition
                if ($IconY) {
                    $IconY += [int]$Script:Settings.AmigaWorkDiskIconYPositionSpacing
                }
                else {
                    $IconY =  [int]$Script:Settings.AmigaWorkDiskIconYPosition
                }
        
            }
            $IconPosScript += "iconpos >NIL: $($Disk.Partition.DeviceName):disk.info type=DISK $IconX $IconY"
            
        }
    }
     
    if ($Emu68Boot) {
        foreach ($Disk in $DefaultDisks) {
            if ($Disk.Disk -eq 'EMU68BOOT'){
                $IconPosScript += "Mount SD0: >NIL:"
                $IconPosScript += "iconpos >NIL: $($Disk.DeviceName):disk.info type=DISK $($Disk.IconX) $($Disk.IconY)"
                $IconPosScript += "Assign SD0: DISMOUNT >NIL:"
                $IconPosScript += "Assign EMU68BOOT: DISMOUNT >NIL:"
            }
        }         
    }
     
    return $IconPosScript
     
}


         
        

    
