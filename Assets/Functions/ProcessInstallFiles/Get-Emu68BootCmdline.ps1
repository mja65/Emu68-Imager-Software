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
    
    if ($UnicamSettings) {

        if ($Script:GUIActions.UnicamEnabled -eq $true){
            If ($Script:GUIActions.UnicamStartonBoot -eq $true){
                $CmdlineToReturn = "$CmdLinetoReturn unicam.boot"
            }
            $CmdlineToReturn = "$CmdLinetoReturn unicam.$($Script:GUIActions.UnicamScalingType) unicam.b=$($Script:GUIActions.UnicamBParameter) unicam.c=$($Script:GUIActions.UnicamCParameter)"
        }

    }

    return $CmdLinetoReturn
    
}

