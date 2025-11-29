function Get-BackdropPrefs {
    param (
        $SourcePath,
        [Switch]$BackdropTRUE,
        [Switch]$BackdropFALSE
    )
    
    #$SourcePath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Env-Archive\Sys\WBConfig.prefs"
    $SourceBytes = [System.Byte[]][System.IO.File]::ReadAllBytes($SourcePath)
    
    if ($BackdropTRUE){
        $HexDataToUse = '01'
    }
    elseif ($BackdropFALSE){
        $HexDataToUse = '00'
    }

    Get-RevisedBinary -SourceBytes $SourceBytes -StartOffset 51 -HexData $HexDataToUse

}
