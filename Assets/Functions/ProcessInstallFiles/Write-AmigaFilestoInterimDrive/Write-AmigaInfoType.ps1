function Write-AmigaInfoType {
    param (
        $IconPath,
        $TypetoSet

    )

    # $HSTAmigaPathtouse = 'E:\Emu68Imager\Working Folder\Programs\HST-Amiga\hst.amiga.exe'
    # $IconPath = 'E:\Emulators\Amiga Files\3.9\hd.info'
    # $TypetoSet = 'Disk'

    if ($TypetoSet -eq 'Disk'){
        $HSTParameter = '1'
    }
    elseif ($TypetoSet -eq 'Drawer'){
        $HSTParameter = '2'
    }
    elseif ($TypetoSet -eq 'Tool'){
        $HSTParameter = '3'
    }
    elseif ($TypetoSet -eq 'Project'){
        $HSTParameter = '4'
    }
    elseif ($TypetoSet -eq 'Garbage'){
        $HSTParameter = '5'
    }
    elseif ($TypetoSet -eq 'Device'){
        $HSTParameter = '6'
    }
    elseif ($TypetoSet -eq 'Kick'){
        $HSTParameter = '7'
    }
    elseif ($TypetoSet -eq 'AppIcon'){
        $HSTParameter = '8'
    }

    $Logoutput = "$($Script:Settings.TempFolder)\LogOutputTemp.txt"

    &  $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTAmigaPath)")) icon update $IconPath -t  $HSTParameter >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount = 0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount ++
            Write-ErrorMessage -Message ('Error in HST-Amiga: '+$ErrorLine)           
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        return $false    
    }
    else{
        return $true
    }     

}