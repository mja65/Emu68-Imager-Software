function Get-ScreenModePrefs {
    param (
        $SourcePath,
        $ScreenMode,
        $ColourDepth
        )
        
       # $SourcePath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2"
       # $ScreenMode = "50AF1303"
       # $ColourDepth = "03" # 8 colours
       
       #$SourcePath = ".\Temp\InterimAmigaDrives\System\Prefs\Env-Archive\Sys\ScreenMode.prefs"
       #$ScreenMode = "PAL:High Res. Laced (640*512)"
       #$ColourDepth = "3"

       $ScreenModeToUse = (($Script:GUIActions.AvailableScreenModesWB |  Where-Object {$_.FriendlyName -eq $ScreenMode}).ModeID) -replace '\$'
       $ColourDepthToUse = [Convert]::ToString($ColourDepth, 16)
       $ColourDepthToUse = ([string]$ColourDepthtoUse).PadLeft(2, "0")

       #Write-debug "ColourDepth: $ColourDepthToUse"
       
       $SourceBytes = [System.Byte[]][System.IO.File]::ReadAllBytes($SourcePath)
        
        $RevisedScreenModeBytes = Get-RevisedBinary -SourceBytes $SourceBytes -StartOffset 50 -HexData $ScreenModeToUse
        $RevisedScreenModewithColourDepthBytes = Get-RevisedBinary -SourceBytes $RevisedScreenModeBytes -StartOffset 59 -HexData $ColourDepthToUse
        
        return $RevisedScreenModewithColourDepthBytes
        
    }