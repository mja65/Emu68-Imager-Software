function Update-FileWithInstallPath {
    param (
        $File,
        $RevisedPath
    )
    # $File = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Assets\AmigaFiles\System\OneTimeRun\Ibrowse"
    # $OriginalPath = "SYS:Programs/Ibrowse"
    # $RevisedPath =  "SYS:Programs/Wibble"
       
    $ReadFile = Get-Content -path $File
    $StringtoReplace = "[PATH]"

    $Pattern = [regex]::Escape($StringtoReplace)
    $RevisedScript = $ReadFile -replace $Pattern, "$RevisedPath/"

    return $RevisedScript

}
