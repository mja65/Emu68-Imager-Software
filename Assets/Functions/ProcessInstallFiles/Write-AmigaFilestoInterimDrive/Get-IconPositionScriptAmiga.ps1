function Get-IconPositionScriptHSTAmiga {
    param (

    )

    $HSTAmigaScript = [System.Collections.Generic.List[PSCustomObject]]::New()

    Get-InputCSVs -IconPositions | ForEach-Object {
        $FilePath = $([System.IO.Path]::GetFullPath("$($Script:Settings.InterimAmigaDrives)\$($_.Drive)\$($_.file)"))
        if (Test-path -Path $FilePath){
           $FilePathtoUse = "`"$FilePath`""
           if ($_.IconX -ne "FREEX"){
               $CurrentX = " --current-x $($_.IconX)"
           }
           else {
               $CurrentX = $null
           }
           if ($_.IconY -ne "FREEY"){
               $CurrentY = " --current-y $($_.IconY)"
           }
           else {
               $CurrentY = $null
           }   
           if ($_.DrawerX){
               $DrawerX = " --drawer-x $($_.DrawerX)"
           }
           else {
               $DrawerX = $null
           }     
           if ($_.DrawerY){
               $DrawerY = " --drawer-y $($_.DrawerY)"
           }
           else {
               $DrawerY = $null
           }      
           if ($_.DrawerWidth){
               $DrawerWidth = " --drawer-width $($_.DrawerWidth)"
           }
           else {
               $DrawerWidth = $null
           }       
               if ($_.DrawerHeight){
               $DrawerHeight = " --drawer-height $($_.DrawerHeight)"
           }
           else {
               $DrawerHeight = $null
           }     
          if ($_.type -eq 'Disk'){
               $TypetoUse = ' --type 1'
           }
           elseif ($_.type -eq 'Drawer'){
               $TypetoUse = ' --type 2'
           }
           elseif ($_.type -eq 'Tool'){
               $TypetoUse = ' --type 3'
           }
           elseif ($_.type -eq 'Project'){
               $TypetoUse = ' --type 4'
           }
           elseif ($_.type -eq 'Garbage'){
               $TypetoUse = ' --type 5'
           }
           elseif ($_.type -eq 'Device'){
               $TypetoUse = ' --type 6'
           }
           elseif ($_.type -eq 'Kick'){
               $TypetoUse = ' --type 7'
           }
           elseif ($_.type -eq 'AppIcon'){
               $TypetoUse = ' --type 8'
           }
       
           $HSTAmigaScript += "icon update $FilePathtoUse$TypetoUse$CurrentX$CurrentY$DrawerX$DrawerY$DrawerWidth$DrawerHeight"           
        
        }
        
    }

    return $HSTAmigaScript
}



