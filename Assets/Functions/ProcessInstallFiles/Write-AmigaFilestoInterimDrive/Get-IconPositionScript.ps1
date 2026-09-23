function Get-IconPositionScript {
    param (
        [Switch]$Emu68Boot,
        [Switch]$AmigaDrives,
        [Switch]$AmigaPositioning
    )
  
    $IconPosScript = [System.Collections.Generic.List[string]]::new()
    $IconPosScript.Add('echo "Positioning icons..."')
    
    $DefaultDisks = Get-InputFileCSV -CSV 'DiskDefaults'
    
    if ($AmigaDrives) {

        if ($AmigaPositioning) {
            (Get-InputFileCSV -CSV 'IconPositions') | ForEach-Object {
                $Params = @()
                if ($_.Type)         { $Params += "type=$($_.Type)" }
                if ($_.IconX)        { $Params += "XPOS=$($_.IconX)" }
                if ($_.IconY)        { $Params += "YPOS=$($_.IconY)" }
                if ($_.DrawerX)      { $Params += "DXPOS=$($_.DrawerX)" }
                if ($_.DrawerY)      { $Params += "DYPOS=$($_.DrawerY)" }
                if ($_.DrawerWidth)  { $Params += "DWIDTH=$($_.DrawerWidth)" }
                if ($_.DrawerHeight) { $Params += "DHEIGHT=$($_.DrawerHeight)" }

                $Remainder = $Params -join ' '
                $IconPosScript.Add("iconpos >NIL: `"SYS:$($_.File)`" $Remainder")
            }
        }
       
        $ListofDisks = if ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries) {
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries
        } else {
            Get-AllGUIPartitionBoundaries -Amiga
        }

        $HashTableforDefaultDisks = @{}
        foreach ($diskDef in $DefaultDisks) {
            $HashTableforDefaultDisks[$diskDef.DeviceName] = $diskDef
        }
        
        $LastIconY = $null
         
        foreach ($Disk in $ListofDisks) {
            $Device = $Disk.Partition.DeviceName
            
            if ($HashTableforDefaultDisks.ContainsKey($Device)) {
                $Match   = $HashTableforDefaultDisks[$Device]
                $IconX   = [int]$Match.IconX
                $IconY   = [int]$Match.IconY
                $DrawerX = [int]$Match.DrawerX
                $DrawerY = [int]$Match.DrawerY
                $DWidth  = [int]$Match.DWidth
                $DHeight = [int]$Match.DHeight
            }
            else {
                $IconX   = [int]$Script:Settings.AmigaWorkDiskIconXPosition
                $DrawerX = [int]$Script:Settings.AmigaWorkDiskDrawerX
                $DrawerY = [int]$Script:Settings.AmigaWorkDiskDrawerY # Fixed Typo from DrawerX
                $DWidth  = [int]$Script:Settings.AmigaWorkDiskDWidth
                $DHeight = [int]$Script:Settings.AmigaWorkDiskDHeight

                $IconY = if ($LastIconY) {
                    $LastIconY + [int]$Script:Settings.AmigaWorkDiskIconYPositionSpacing
                } else {
                    [int]$Script:Settings.AmigaWorkDiskIconYPosition
                }
            }

            $IconPosScript.Add("iconpos >NIL: $Device:disk.info type=DISK")
            $IconPosScript.Add("iconpos >NIL: $Device:disk.info XPOS=$IconX YPOS=$IconY DXPOS=$DrawerX DYPOS=$DrawerY DWIDTH=$DWidth DHEIGHT=$DHeight")
            
            $LastIconY = $IconY
        }
    }
     
    if ($Emu68Boot) {
        $IconPosScript.Add('IF NOT $System EQ "UAE"')
        
        foreach ($Disk in $DefaultDisks) {
            if ($Disk.Disk -eq 'EMU68BOOT') {
                $Device = $Disk.DeviceName
                $IconPosScript.Add("    iconpos >NIL: $Device:disk.info type=DISK")
                $IconPosScript.Add("    iconpos >NIL: $Device:disk.info XPOS=$($Disk.IconX) YPOS=$($Disk.IconY) DXPOS=$($Disk.DrawerX) DYPOS=$($Disk.DWidth) DWIDTH=$($Disk.DWidth) DHEIGHT=$($Disk.DHeight)")
            }
        }  
        $IconPosScript.Add("ENDIF")    
    }
     
    return $IconPosScript
}

# function Get-IconPositionScript {
#     param (

#     [Switch]$Emu68Boot,
#     [Switch]$AmigaDrives,
#     [Switch]$AmigaPositioning

#     )

#     $IconPosScript = @()
    
#     $IconPosScript += "echo `"Positioning icons...`""
#     $DefaultDisks = (Get-InputFileCSV -CSV 'DiskDefaults')
    
#     if ($AmigaDrives){

#         if ($AmigaPositioning){
#             (Get-InputFileCSV -CSV 'IconPositions') | ForEach-Object {
#                 $TypetoUse = $null
#                 $IconXtoUse = $null
#                 $IconytoUse = $null
#                 $DrawerXtoUse = $null
#                 $DrawerYtoUse = $null
#                 $DrawerWidthToUse = $null
#                 $DrawerHeightToUse = $null
#                 if ($_.Type){
#                     $TypetoUse = "type=$($_.Type) "
#                 }
#                 if ($_.IconX){
#                     $IconXtoUse = "XPOS=$($_.IconX) "                
#                 }
#                 if ($_.Icony){
#                     $IconYtoUse = "YPOS=$($_.IconY) "    
#                 }
#                 if ($_.DrawerX){
#                    $DrawerXtoUse = "DXPOS=$($_.DrawerX) "
#                }
#                if ($_.DrawerY){
#                    $DrawerYtoUse = "DYPOS=$($_.DrawerY) "
#                }
#                if ($_.DrawerWidth){
#                    $DrawerWidthToUse = "DWIDTH=$($_.DrawerWidth) "
#                }
#                if ($_.DrawerHeight){
#                    $DrawerHeightToUse = "DHEIGHT=$($_.DrawerHeight)"
#                }
#                $Remainder = "$TypetoUse$IconXtoUse$IconytoUse$DrawerXtoUse$DrawerYtoUse$DrawerWidthToUse$DrawerHeightToUse"
#                $IconPosScript += "iconpos >NIL: `"SYS:$($_.File)`" $Remainder"
               
#             }
#         }
       
#         if  ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries){
#             $ListofDisks = $Script:GUICurrentStatus.AmigaPartitionsandBoundaries
#         }
#         else {
#             $ListofDisks = (Get-AllGUIPartitionBoundaries -Amiga)
#         }

#         $HashTableforDefaultDisks = @{} # Clear Hash
#         (Get-InputFileCSV -CSV 'DiskDefaults') | ForEach-Object {
#             $HashTableforDefaultDisks[$_.DeviceName] = @($_.IconX,$_.IconY,$_.DrawerX,$_.DrawerY,$_.DWidth,$_.DHeight) 
#         }
        
#         $LastIconY = $null
         
#         foreach ($Disk in $ListofDisks) {
#             if ($HashTableforDefaultDisks.ContainsKey($Disk.Partition.DeviceName)){
#                 $IconX = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[0])
#                 $IconY = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[1])
#                 $DrawerX = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[2])
#                 $DrawerY = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[3])
#                 $DWidth = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[4])
#                 $DHeight = [int]($HashTableforDefaultDisks.($Disk.Partition.DeviceName)[5])
#             }
#             else {
#                 $IconX = [int]$Script:Settings.AmigaWorkDiskIconXPosition
#                 $DrawerX = [int]$Script:Settings.AmigaWorkDiskDrawerX
#                 $DrawerY = [int]$Script:Settings.AmigaWorkDiskDrawerX
#                 $DWidth = [int]$Script:Settings.AmigaWorkDiskDWidth
#                 $DHeight = [int]$Script:Settings.AmigaWorkDiskDHeight

#                 if ($LastIconY) {
#                     $IconY = $LastIconY + [int]$Script:Settings.AmigaWorkDiskIconYPositionSpacing
#                 }
#                 else {
#                     $IconY =  [int]$Script:Settings.AmigaWorkDiskIconYPosition
#                 }
        
#             }
#             $IconPosScript += "iconpos >NIL: $($Disk.Partition.DeviceName):disk.info type=DISK"
#             $IconPosScript += "iconpos >NIL: $($Disk.Partition.DeviceName):disk.info XPOS=$IconX YPOS=$IconY DXPOS=$DrawerX DYPOS=$DrawerY DWIDTH=$DWidth DHEIGHT=$DHeight"
            
#             $LastIconY = $IconY
#         }
#     }
     
#     if ($Emu68Boot) {
#     #    $IconPosScript += "Mount SD0: >NIL:"
#     $IconPosScript += "IF NOT `$System EQ `"UAE`""
#         # $IconPosScript += "   Delete EMU68BOOT:cmdline.txt QUIET"
#         # $IconPosScript += "   rename from EMU68BOOT:cmdlineBAK.txt to EMU68BOOT:cmdline.txt"
#         foreach ($Disk in $DefaultDisks) {
#             if ($Disk.Disk -eq 'EMU68BOOT'){
#                 $IconPosScript += "   iconpos >NIL: $($Disk.DeviceName):disk.info type=DISK"
#                 $IconPosScript += "   iconpos >NIL: $($Disk.DeviceName):disk.info XPOS=$($Disk.IconX) YPOS=$($Disk.IconY) DXPOS=$($Disk.DrawerX) DYPOS=$($DIsk.DrawerY) DWIDTH=$($Disk.DWidth) DHEIGHT=$($Disk.DHeight)"

#             }
#         }  
#         $IconPosScript += "ENDIF"    
#     #    $IconPosScript += "WAIT 1"                               
#     #    $IconPosScript += "Assign SD0: DISMOUNT >NIL:"
#     #    $IconPosScript += "Assign EMU68BOOT: DISMOUNT >NIL:"
#     }
     
#     return $IconPosScript
     
# }


         
        

    
