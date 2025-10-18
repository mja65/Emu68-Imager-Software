function Write-IconPositions {
    param (
        
    )
      Get-InputCSVs -IconPositions | ForEach-Object {
          $IconXtoUse = $null
          $IconYtoUse = $null
          $DrawerXtoUse = $null
          $DrawerYtoUse = $null
          $DrawerHeighttoUse = $null
          $DrawerWidthtoUse = $null
          $PathtoInfofile = "$($Script:Settings.InterimAmigaDrives)\$($_.Drive)\$($_.File)"
          $arguments = $null    
          if (test-path $PathtoInfofile){
             If ($_.IconX -ne "" -and $_.Iconx -ne "FREEX"){
                    $IconXtoUse = $_.IconX
                }
                If ($_.IconY -ne "" -and $_.IconY -ne "FREEY"){
                    $IconYtoUse = $_.IconY
                }
                If ($_.DrawerX -ne "" -and $_.DrawerX -ne "FREEX"){
                    $DrawerXtoUse = $_.DrawerX
                }
                If ($_.DrawerY -ne "" -and $_.DrawerY -ne "FREEY"){
                    $DrawerYtoUse = $_.DrawerY
                } 
                if ($_.DrawerWidth -ne ""){
                    $DrawerWidthtoUse = $_.DrawerWidth
                } 
                if ($_.DrawerHeight -ne ""){
                    $DrawerHeighttoUse = $_.DrawerHeight
                } 
                if (($IconXtoUse) -or ($IconYtoUse) -or ($DrawerXtoUse) -or  ($DrawerYtoUse) -or ($DrawerHeighttoUse) -or ($DrawerWidthtoUse)){                   
                    $arguments = @("icon", "update", $PathtoInfofile)
                    if ($IconXtoUse){
                        $arguments += @("--current-x",$IconXtoUse)
                    }
                    if ($IconYtoUse){
                        $arguments += @("--current-y",$IconYtoUse)
                    }
                    if ($DrawerXtoUse){
                         $arguments += @("--drawer-x", $DrawerXtoUse)
                    }
                    if ($DrawerYtoUse){
                         $arguments += @("--drawer-y", $DrawerYtoUse)
                    }
                    if ($DrawerWidthtoUse){
                         $arguments += @("--drawer-width", $DrawerWidthtoUse)
                    }
                    if ($DrawerHeighttoUse){
                         $arguments += @("--drawer-height", $DrawerHeighttoUse)
                    }
                        Write-AmigaIconPositiontoInfoFile -Arguments $arguments -IconPath $PathtoInfofile
            
                }
            }
        }

    }

                    
                    




          
#     Get-InputCSVs -IconPositions | ForEach-Object {
#     #    if ($_.file -eq "PiStorm\Documentation.info"){
#             $IconXtoUse = $null
#             $IconYtoUse = $null
#             $DrawerXtoUse = $null
#             $DrawerYtoUse = $null
#             $DrawerHeighttoUse = $null
#             $DrawerWidthtoUse = $null
#             $PathtoInfofile = "$($Script:Settings.InterimAmigaDrives)\$($_.Drive)\$($_.File)"    
#             if (test-path $PathtoInfofile){
#                 #  Get-IconCoordinates -PathtoIcon $PathtoInfofile 
#                 If ($_.IconX -ne "" -and $_.Iconx -ne "FREEX"){
#                     $IconXtoUse = $_.IconX
#                 }
#                 If ($_.IconY -ne "" -and $_.IconY -ne "FREEY"){
#                     $IconYtoUse = $_.IconY
#                 }
#                 If ($_.DrawerX -ne "" -and $_.DrawerX -ne "FREEX"){
#                     $DrawerXtoUse = $_.DrawerX
#                 }
#                 If ($_.DrawerY -ne "" -and $_.DrawerY -ne "FREEY"){
#                     $DrawerYtoUse = $_.DrawerY
#                 } 
#                 if ($_.DrawerHeight -ne ""){
#                     $DrawerHeighttoUse = $_.DrawerHeight
#                 } 
#                 if ($_.DrawerWidth -ne ""){
#                     $DrawerWidthtoUse = $_.DrawerWidth
#                 } 
#                 if (($IconXtoUse) -or ($IconYtoUse) -or ($DrawerXtoUse) -or  ($DrawerYtoUse) -or ($DrawerHeighttoUse) -or ($DrawerWidthtoUse)){           
#                     Write-InformationMessage -Message "Setting coordinate details for:$PathtoInfofile"
#                     Write-InformationMessage -Message "Setting Iconx:$IconXtoUse IconY:$IconYtoUse DrawerX:$DrawerXtoUse DrawerY:$DrawerYtoUse DrawerHeight:$DrawerHeighttoUse DrawerWidth:$DrawerWidthtouse"
#                     Write-IconCoordinates -PathtoIcon $PathtoInfofile -PathtoNewIcon $PathtoInfofile `
#                                             -IconXNew $IconXtoUse -IconYNew $IconYtoUse -DrawerXNew $DrawerXtoUse -DrawerYNew $DrawerYtoUse `
#                                             -DrawerWidthNew $DrawerWidthtoUse -DrawerHeightNew $DrawerHeighttoUse

#                 }       
#             }
#             else {
#                 #Write-host $PathtoInfofile
#             }

#     #    }
#     }
# }
  
#Get-IconCoordinates -PathtoIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm\Documentation.info"
#Write-IconCoordinates -PathtoIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm\Documentation.info" --PathtoNewIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm\Documentation.info" -IconXNew 413 -IconYNew 41
 
# 
# Write-IconCoordinates -PathtoIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm.info" -PathtoNewIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm.info" -IconXNew 412 -IconYNew 4 -DrawerXNew 27 -DrawerYNew 73 -DrawerWidth 613 -DrawerHeight 163
# Write-IconCoordinates -PathtoIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm.info" -PathtoNewIcon "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\PiStorm.info" -
# # $IconXNew 412 
# # $IconYNew 4 
# # $DrawerXNew 27 
# # $DrawerYNew 73 
# # $DrawerWidth 613 
# # $DrawerHeight 163