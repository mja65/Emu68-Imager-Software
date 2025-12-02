function Read-AmigaTooltypes {
    param (
        $IconPath,
        $ToolTypesPath
        
    )
    $Logoutput = "$($Script:Settings.TempFolder)\LogOutputTemp.txt"

    Write-InformationMessage -Message "Extracting Tooltypes for info file(s): $IconPath to $ToolTypesPath" 
      
    & $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTAmigaPath)")) icon tooltypes export $IconPath $ToolTypesPath | Tee-Object -variable Logoutput
    $ErrorCount  =0
    foreach ($ErrorLine in $Logoutput){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount ++
            Write-ErrorMessage -Message "Error in HST-Amiga: $ErrorLine"           
        }
    }
    if ($ErrorCount -ge 1){
        return $false   
    }
    else{
        return $true
    }
}