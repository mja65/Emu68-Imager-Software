function Update-ConfigTXT {
    param (
        $PathtoConfigTXT,
        $PathtoExportedConfigTXT
    )
    
    # $PathtoConfigTXT = "C:\Users\Matt\OneDrive\Documents\EmuImager2\Assets\AmigaFiles\EMU68Boot\config.txt"
    # $PathtoExportedConfigTXT ="C:\Users\Matt\OneDrive\Documents\EmuImager2\Temp\InterimAmigaDrives\Emu68Boot\config.txt"

    $ConfigTxt = Get-Content -Path $PathtoConfigTXT
    Write-InformationMessage -Message 'Preparing Config.txt'
    $RevisedConfigTxt = @()
    
    If ($Script:GUIActions.ScreenModetoUse -eq "Custom"){
        $CVTAspectRatio = (Get-CVTAspectRatio -AspectRatio $Script:GUIActions.CustomScreenMode_Aspect)
        $CVTMargins = (get-cvtMargins -Margins $Script:GUIActions.CustomScreenMode_Margins)
        $CVTInterlace = (get-cvtInterlace -Interlace $Script:GUIActions.CustomScreenMode_Interlace)
        $CVTRB = (get-cvtBlanking -RB $Script:GUIActions.CustomScreenMode_RB)
        $CVT_String = "$($Script:GUIActions.CustomScreenMode_Width) $($Script:GUIActions.CustomScreenMode_Height) $($Script:GUIActions.CustomScreenMode_Framerate) $CVTAspectRatio $CVTMargins $CVTInterlace $CVTRB" 
    }
      
    foreach ($Line in $ConfigTxt) {
        if ($line -eq '[ROMPATH]'){
            $RevisedConfigTxt += "initramfs $($Script:GUIActions.FoundKickstarttoUse.Fat32Name)"
        }
        elseif ($line -eq '[DTOVERLAY]'){
            $RevisedConfigTxt += Get-UnicamConfigTxt

        }
        elseif ($line -eq '[VIDEOMODES]'){
            $RevisedConfigTxt +="# The following section defines the screenmode for your monitor for output from the Raspberry Pi. If you wish to "
            $RevisedConfigTxt +="# select a different screenmode you can comment out the existing mode and remove the comment marks from the new one."        
            If ($Script:GUIActions.ScreenModetoUse -eq "Custom"){
                $RevisedConfigTxt += "hdmi_cvt=$CVT_String"
                $RevisedConfigTxt += "hdmi_group=2"
                $RevisedConfigTxt += "hdmi_mode=87"
            }   
            $Script:GUIActions.AvailableScreenModes | ForEach-Object {
                if ($_.Name -eq $Script:GUIActions.ScreenModetoUse){
                    $RevisedConfigTxt += ""
                    $RevisedConfigTxt += "# ScreenMode: $($_.FriendlyName) (Currently Selected). To enable a different screenmode, comment out this one and enable a different one."
                    if (-not ($_.hdmi_group.Length -eq 0)){
                        $RevisedConfigTxt += "hdmi_group=$($_.hdmi_group)"
                    }
                    if (-not ($_.hdmi_mode.Length -eq 0)){
                        $RevisedConfigTxt += "hdmi_mode=$($_.hdmi_mode)"
                    }
                    if (-not ($_.hdmi_cvt.length -eq 0)){
                        $RevisedConfigTxt += "hdmi_cvt=$($_.hdmi_cvt)"
                    }
                    if (-not ($_.max_framebuffer_width.length -eq 0)){
                        $RevisedConfigTxt += "max_framebuffer_width=$($_.max_framebuffer_width)"
                    }
                    if (-not ($_.max_framebuffer_height.length -eq 0)){
                        $RevisedConfigTxt += "max_framebuffer_height=$($_.max_framebuffer_height)"
                    }
                    if (-not ($_.hdmi_pixel_freq_limit.length -eq 0)){
                        $RevisedConfigTxt += "hdmi_pixel_freq_limit=$($_.hdmi_pixel_freq_limit)"
                    }
                    if (-not ($_.disable_overscan.length -eq 0)){
                        $RevisedConfigTxt += "disable_overscan=$($_.disable_overscan)"
                    }
                }
                else {
                    $RevisedConfigTxt += ""
                    $RevisedConfigTxt += "# ScreenMode: $($_.FriendlyName)"
                    if (-not ($_.hdmi_group.Length -eq 0)){
                        $RevisedConfigTxt += "# hdmi_group=$($_.hdmi_group)"
                    }
                    if (-not ($_.hdmi_mode.Length -eq 0)){
                        $RevisedConfigTxt += "# hdmi_mode=$($_.hdmi_mode)"
                    }
                    if (-not ($_.hdmi_cvt.length -eq 0)){
                        $RevisedConfigTxt += "# hdmi_cvt=$($_.hdmi_cvt)"
                    }
                    if (-not ($_.max_framebuffer_width.length -eq 0)){
                        $RevisedConfigTxt += "# max_framebuffer_width=$($_.max_framebuffer_width)"
                    }
                    if (-not ($_.max_framebuffer_height.length -eq 0)){
                        $RevisedConfigTxt += "# max_framebuffer_height=$($_.max_framebuffer_height)"
                    }
                    if (-not ($_.hdmi_pixel_freq_limit.length -eq 0)){
                        $RevisedConfigTxt += "# hdmi_pixel_freq_limit=$($_.hdmi_pixel_freq_limit)"
                    }
                    if (-not ($_.disable_overscan.length -eq 0)){
                        $RevisedConfigTxt += "# disable_overscan=$($_.disable_overscan)"
                    }
                }
            }
        }
        else{
            $RevisedConfigTxt += "$Line"
        }    
    }

    Export-TextFileforAmiga -DatatoExport $RevisedConfigTxt -ExportFile $PathtoExportedConfigTXT -AddLineFeeds 'TRUE' 
    
}
