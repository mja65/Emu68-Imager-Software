function Write-AmigaIconPositiontoInfoFile {
    param (
        $IconPath,
        $Arguments
        
    )
    $Logoutput = "$($Script:Settings.TempFolder)\LogOutputTemp.txt"

    Write-InformationMessage -Message "Setting coordinate details for file: $IconPath" 
    
    & $Script:ExternalProgramSettings.HSTAmigaPath $arguments >$Logoutput
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