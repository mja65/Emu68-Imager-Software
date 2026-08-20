function Get-Emu68BootCmdline {
    param (
        [Switch]$SDLowSpeed,
        [Switch]$Firstboot,
        [Switch]$UnicamSettings

    )
 
    if ($SDLowSpeed){
        $CmdLinetoReturn = "sd.low_speed emmc.low_speed $($Script:Settings.Emu68BootCmdline)"
    }
    else {
        $CmdLinetoReturn = $Script:Settings.Emu68BootCmdline
    }
    if ($Firstboot){
        if  (($Script:GUIActions.InstallOSFiles -eq $true) -and (([System.Version]$Script:GUIActions.KickstartVersiontoUse).Major -eq 3) -and (([System.Version]$Script:GUIActions.KickstartVersiontoUse).Minor -eq 2)){
            $CmdLinetoReturn = "buptest=512 bupiter=1 $CmdLinetoReturn" 
        } 
    }
    
    # Emu68 1.1 configures FrameThrower through dtoverlay=unicam in config.txt.
    # Keep the switch for shared callers, but never emit obsolete unicam.*
    # cmdline parameters alongside the overlay.

    return $CmdLinetoReturn
    
}
