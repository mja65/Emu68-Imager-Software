function Test-Architecture {
    param (
        
    )

    if (($Script:Settings.Architecture -eq '64-bit') -or ($Script:Settings.Architecture -eq '64 bit') -or ($Script:Settings.Architecture -eq '64 Bits')){
        $Valuetoreturn = "64bit"
    }
    elseif ($Script:Settings.Architecture -match 'ARM 64-bit'){
        $Valuetoreturn = "ARM"
        Write-WarningMessage -Message "You are running ARM! While some users report this work, this is unsupported!"
    }
    else {
        $Valuetoreturn = "Other"
    }
    
    return $Valuetoreturn

}