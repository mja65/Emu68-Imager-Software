function Write-CustomAmigaKickstart {
    param (
        $Script
    )

    Write-InformationMessage "Installing Capitoline if not already installed"
    if (-not (Get-StartupFiles -InstallTime "ProcessImage")){
        Write-WarningMessage -Message "Unable to install Capitoline! Reverting to standard Amiga kickstart ROM"
        return $false
    }
   
    $CapitolineTempScriptPath = Join-PathMulti $Script:Settings.TempFolder "CapitolineScript.txt" -UseFullPath
    $ProgramPath = Join-Path $CapitolineTempScriptPath "capcli.exe"
    
    $Script | Out-File -FilePath $CapitolineTempScriptPath

    Write-InformationMessage "Writing custom Rom"

    & $ProgramPath $Script

    return $true

}
