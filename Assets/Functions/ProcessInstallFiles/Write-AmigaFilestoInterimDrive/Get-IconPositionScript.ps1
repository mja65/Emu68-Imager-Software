function Get-IconPositionScript {
    param (

    [Switch]$Emu68Boot,
    [Switch]$AmigaDrives,
    [Switch]$AmigaPositioning

    )

    $IconPosScript = @()
    
    $IconPosScript += "echo `"Positioning icons...`""
    $DefaultDisks = Get-InputCSVs -Diskdefaults
    
    if ($AmigaDrives){

        if ($AmigaPositioning){
            Get-InputCSVs -IconPositions | ForEach-Object {
                $TypetoUse = $null
                $IconXtoUse = $null
                $IconytoUse = $null
                $DrawerXtoUse = $null
                $DrawerYtoUse = $null
                $DrawerWidthToUse = $null
                $DrawerHeightToUse = $null
                if ($_.Type){
                    $TypetoUse = "type=$($_.Type) "
                }
                if ($_.IconX){
                    $IconXtoUse = "XPOS=$($_.IconX) "                
                }
                if ($_.Icony){
                    $IconYtoUse = "YPOS=$($_.IconY) "    
                }
                if ($_.DrawerX){
                   $DrawerXtoUse = "DXPOS=$($_.DrawerX) "
               }
               if ($_.DrawerY){
                   $DrawerYtoUse = "DYPOS=$($_.DrawerY) "
               }
               if ($_.DrawerWidth){
                   $DrawerWidthToUse = "DWIDTH=$($_.DrawerWidth) "
               }
               if ($_.DrawerHeight){
                   $DrawerHeightToUse = "DHEIGHT=$($_.DrawerHeight)"
               }
               $Remainder = "$TypetoUse$IconXtoUse$IconytoUse$DrawerXtoUse$DrawerYtoUse$DrawerWidthToUse$DrawerHeightToUse"
               $IconPosScript += "iconpos >NIL: `"SYS:$($_.File)`" $Remainder"
               
            }
        }
       
        if  ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries){
            $ListofDisks = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries
        }
        else {
            $ListofDisks = (Get-AllGUIPartitionBoundaries -Amiga)
        }

        $HashTableforDefaultDisks = @{} # Clear Hash
        Get-InputCSVs -Diskdefaults | ForEach-Object {
            $HashTableforDefaultDisks[$_.DeviceName] = @($_.IconX,$_.IconY,$_.DrawerX,$_.DrawerY,$_.DWidth,$_.DHeight) 
        }
        
        $LastIconY = $null
         
        foreach ($Disk in $ListofDisks) {
            if ($HashTableforDefaultDisks.ContainsKey($Disk.Partition.DeviceName)){
                $IconX = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[0])
                $IconY = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[1])
                $DrawerX = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[2])
                $DrawerY = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[3])
                $DWidth = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[4])
                $DHeight = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[5])
            }
            else {
                $IconX = [int]$Script:Settings.AmigaWorkDiskIconXPosition
                $DrawerX = [int]$Script:Settings.AmigaWorkDiskDrawerX
                $DrawerY = [int]$Script:Settings.AmigaWorkDiskDrawerX
                $DWidth = [int]$Script:Settings.AmigaWorkDiskDWidth
                $DHeight = [int]$Script:Settings.AmigaWorkDiskDHeight

                if ($LastIconY) {
                    $IconY = $LastIconY + [int]$Script:Settings.AmigaWorkDiskIconYPositionSpacing
                }
                else {
                    $IconY =  [int]$Script:Settings.AmigaWorkDiskIconYPosition
                }
        
            }
            $IconPosScript += "iconpos >NIL: $($Disk.Partition.DeviceName):disk.info type=DISK"
            $IconPosScript += "iconpos >NIL: $($Disk.Partition.DeviceName):disk.info XPOS=$IconX YPOS=$IconY DXPOS=$DrawerX DYPOS=$DrawerY DWIDTH=$DWidth DHEIGHT=$DHeight"
            
            $LastIconY = $IconY
        }
    }
     
    if ($Emu68Boot) {
    #    $IconPosScript += "Mount SD0: >NIL:"
    $IconPosScript += "IF NOT `$System EQ `"WinUAE`""
        # $IconPosScript += "   Delete EMU68BOOT:cmdline.txt QUIET"
        # $IconPosScript += "   rename from EMU68BOOT:cmdlineBAK.txt to EMU68BOOT:cmdline.txt"
        foreach ($Disk in $DefaultDisks) {
            if ($Disk.Disk -eq 'EMU68BOOT'){
                $IconPosScript += "   iconpos >NIL: $($Disk.DeviceName):disk.info type=DISK"
                $IconPosScript += "   iconpos >NIL: $($Disk.DeviceName):disk.info XPOS=$($Disk.IconX) YPOS=$($Disk.IconY) DXPOS=$($Disk.DrawerX) DYPOS=$($DIsk.DrawerY) DWIDTH=$($Disk.DWidth) DHEIGHT=$($Disk.DHeight)"

            }
        }  
        $IconPosScript += "ENDIF"    
    #    $IconPosScript += "WAIT 1"                               
    #    $IconPosScript += "Assign SD0: DISMOUNT >NIL:"
    #    $IconPosScript += "Assign EMU68BOOT: DISMOUNT >NIL:"
    }
     
    return $IconPosScript
     
}


         
        

    
