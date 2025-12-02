function Write-AmigaTooltypes {
    param (
        $IconPath,
        $ToolTypesPath
    )
    
    $Logoutput = "$($Script:Settings.TempFolder)\LogOutputTemp.txt"
    Write-InformationMessage -Message "Updating info file: $IconPath based on Tooltypes from $ToolTypesPath" 
    & $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTAmigaPath)")) icon tooltypes import $IconPath $ToolTypesPath | Tee-Object -variable Logoutput
    $ErrorCount = 0
    foreach ($ErrorLine in $Logoutput){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount ++
            Write-ErrorMessage -Message "Error in HST-Amiga: $ErrorLine"           
        }
    }
    if ($ErrorCount -ge 1){
        $null = Remove-Item ($Logoutput) -Force
        return $false    
    }
    else{
        return $true
    }        
}